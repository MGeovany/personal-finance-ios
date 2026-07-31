import SwiftUI

/// How much is left this week, with the day strip and the usual spend categories.
///
/// Styled like the debts summary: a hero amount up top, then the details under it.
/// Pedidos Ya is a count (used/allowed), not money, so it matches how the plan is
/// explained elsewhere.
struct WeeklyStatusCard: View {
    let week: BudgetConsumption
    let month: BudgetConsumption
    let days: [HomeViewModel.WeekDayProgress]
    let deliveryOrdersUsed: Int
    let deliveryOrdersAllowed: Int
    let outingsSpent: Money
    let outingsBudget: Money
    let spentToday: Money
    let money: MoneyFormatting
    let currency: CurrencyCode

    @State private var appeared = false

    var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: DesignSystem.Space.l) {
                StatTile(
                    label: "Disponible para esta semana",
                    value: money.string(week.remaining, currency: currency),
                    tint: amountTint
                )

                AnimatedProgressBar(fraction: week.usedFraction, tint: progressTint, height: 14)

                if week.isOverBudget {
                    Chip(text: "Sin disponible", tint: Palette.caution)
                }

                dayStrip

                RowDivider()

                DetailRow(
                    label: "Pedidos Ya",
                    value: "\(deliveryOrdersUsed)/\(deliveryOrdersAllowed)",
                    tint: deliveryTint,
                    icon: "bag",
                    caption: deliveryCaption
                )
                DetailRow(
                    label: "Salidas y extras",
                    value: "\(money.string(outingsSpent, currency: currency))/\(money.digits(outingsBudget))",
                    tint: outingsTint,
                    icon: "party.popper",
                    caption: outingsCaption
                )
                DetailRow(
                    label: "Queda del mes",
                    value: money.string(month.remaining, currency: currency),
                    tint: monthTint,
                    icon: "calendar",
                    caption: "presupuesto variable"
                )
                DetailRow(
                    label: "Gastado hoy",
                    value: money.string(spentToday, currency: currency),
                    tint: Palette.critical,
                    icon: "sun.max",
                    caption: "en todas las categorías"
                )
            }
        }
        .onAppear {
            appeared = false
            withAnimation(DesignSystem.Motion.present.delay(0.05)) {
                appeared = true
            }
        }
    }

    private var dayStrip: some View {
        HStack(alignment: .bottom, spacing: DesignSystem.Space.xs) {
            ForEach(days) { day in
                VStack(spacing: 6) {
                    Capsule()
                        .fill(dayFill(for: day))
                        .frame(height: dayHeight(for: day))
                        .frame(maxWidth: .infinity)
                        .overlay {
                            if isPast(day) {
                                DiagonalHatch(color: hatchColor(for: day))
                                    .clipShape(Capsule())
                            }
                        }
                        .overlay {
                            if day.isToday {
                                Capsule()
                                    .strokeBorder(progressTint, lineWidth: 1.5)
                            }
                        }
                        .scaleEffect(y: appeared ? 1 : 0.15, anchor: .bottom)
                        .opacity(appeared ? 1 : 0.35)
                        .animation(
                            DesignSystem.Motion.present.delay(0.04 * Double(day.id)),
                            value: appeared
                        )

                    Text(day.label)
                        .font(Typography.captionStrong)
                        .foregroundStyle(day.isToday ? Palette.primaryText : Palette.tertiaryText)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 72, alignment: .bottom)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progreso semanal de lunes a domingo")
    }

    private func isPast(_ day: HomeViewModel.WeekDayProgress) -> Bool {
        !day.isToday && !day.isFuture
    }

    private func hatchColor(for day: HomeViewModel.WeekDayProgress) -> Color {
        if day.spent > 0 {
            return Palette.primaryText.opacity(0.22)
        }
        return Palette.primaryText.opacity(0.16)
    }

    private var deliveryCaption: String {
        let remaining = max(0, deliveryOrdersAllowed - deliveryOrdersUsed)
        if deliveryOrdersAllowed == 0 {
            return "sin cupo este mes"
        }
        if deliveryOrdersUsed > deliveryOrdersAllowed {
            return "cupo del mes usado"
        }
        if remaining == 1 {
            return "te queda 1 este mes"
        }
        return "te quedan \(remaining) este mes"
    }

    private var deliveryTint: Color {
        if deliveryOrdersAllowed == 0 || deliveryOrdersUsed > deliveryOrdersAllowed {
            return Palette.critical
        }
        if deliveryOrdersUsed == deliveryOrdersAllowed {
            return Palette.caution
        }
        return Palette.primaryText
    }

    private var outingsCaption: String {
        if outingsBudget <= 0 {
            return "sin cupo este mes"
        }
        if outingsSpent > outingsBudget {
            return "cupo del mes usado"
        }
        let remaining = outingsBudget - outingsSpent
        if remaining <= 0 {
            return "cupo del mes usado"
        }
        return "te quedan \(money.string(remaining, currency: currency)) este mes"
    }

    private var outingsTint: Color {
        if outingsBudget <= 0 || outingsSpent > outingsBudget {
            return Palette.critical
        }
        if outingsSpent >= outingsBudget {
            return Palette.caution
        }
        return Palette.primaryText
    }

    private var amountTint: Color {
        if week.isOverBudget || week.isNearLimit { return Palette.critical }
        return Palette.primaryText
    }

    private var progressTint: Color {
        if week.isOverBudget || week.isNearLimit { return Palette.critical }
        return Palette.positive
    }

    private var monthTint: Color {
        if month.isOverBudget || month.isNearLimit { return Palette.critical }
        return Palette.primaryText
    }

    private func dayHeight(for day: HomeViewModel.WeekDayProgress) -> CGFloat {
        if day.isFuture { return 16 }
        let daily = week.budget > 0 ? week.budget / 7 : 0
        let intensity = daily > 0 ? min(1, (day.spent / daily).doubleValue) : (day.spent > 0 ? 1 : 0)
        return 16 + 36 * intensity
    }

    private func dayFill(for day: HomeViewModel.WeekDayProgress) -> Color {
        if day.isFuture { return Palette.surfaceSunken }
        if day.spent <= 0 { return Palette.surfaceSunken }
        return progressTint.opacity(day.isToday ? 1 : 0.7)
    }
}
