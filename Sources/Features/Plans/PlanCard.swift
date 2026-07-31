import SwiftUI

/// One plan as a selectable card: the date, the payment, and the sentence that
/// explains the trade-off. Kept airy so three options can sit without feeling dense.
struct PlanCard: View {
    let plan: FinancialPlan
    let isSelected: Bool
    let isRecommended: Bool
    let summary: String
    let money: MoneyFormatting
    let dates: PlanDateFormatting
    let currency: CurrencyCode
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: DesignSystem.Space.xxl) {
                header

                Text(plan.freedomDate.map { dates.compactDayAndMonth($0, relativeTo: Date()) } ?? "Sin fecha")
                    .font(Typography.display(28, .displaySemibold))
                    .foregroundStyle(isSelected ? Palette.accent : Palette.primaryText)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)

                HStack(alignment: .top, spacing: DesignSystem.Space.xxxl) {
                    StatTile(
                        label: "Pago mensual",
                        value: money.string(plan.monthlyDebtPayment, currency: currency),
                        size: .small
                    )
                    StatTile(
                        label: "Gasto semanal",
                        value: money.string(plan.weekly.averageWeekly, currency: currency),
                        size: .small
                    )
                }

                Text(summary)
                    .font(Typography.text(15, .light))
                    .foregroundStyle(Palette.tertiaryText)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, DesignSystem.Space.xxs)
            }
            .padding(DesignSystem.Space.xxxl)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: Layout.cardRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Layout.cardRadius, style: .continuous)
                    .strokeBorder(isSelected ? Palette.accent : Color.clear, lineWidth: 1.5)
            }
            .softShadow(isSelected ? .floating : .raised)
            .contentShape(RoundedRectangle(cornerRadius: Layout.cardRadius, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: DesignSystem.Space.m) {
            Text(plan.name)
                .font(Typography.display(22, .displayBold))
                .foregroundStyle(Palette.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            if isRecommended {
                Text("Recomendado")
                    .font(Typography.caption)
                    .foregroundStyle(Palette.secondaryText)
                    .lineLimit(1)
                    .padding(.horizontal, DesignSystem.Space.m)
                    .padding(.vertical, DesignSystem.Space.xs)
                    .background(Palette.surfaceMuted, in: Capsule())
            }

            Spacer(minLength: DesignSystem.Space.s)

            DifficultyBars(difficulty: plan.difficulty)
        }
    }
}
