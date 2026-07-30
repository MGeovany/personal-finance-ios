import SwiftUI

/// One plan as a selectable card: the date, the payment, and the sentence that
/// explains the trade-off.
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
            CardContainer {
                VStack(alignment: .leading, spacing: Layout.gap) {
                    header

                    Text(plan.freedomDate.map { dates.dayAndMonth($0, relativeTo: Date()) } ?? "Sin fecha")
                        .font(Typography.statistic)
                        .foregroundStyle(isSelected ? Palette.accent : Palette.primaryText)

                    HStack(spacing: Layout.sectionGap) {
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
                        .font(Typography.body)
                        .foregroundStyle(Palette.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: Layout.cardRadius, style: .continuous)
                    .strokeBorder(isSelected ? Palette.accent : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    private var header: some View {
        HStack(spacing: Layout.tightGap) {
            Text(plan.name)
                .font(Typography.title)
                .foregroundStyle(Palette.primaryText)

            if isRecommended {
                Chip(text: "Recomendado", tint: Palette.accent)
            }

            Spacer()

            DifficultyDots(difficulty: plan.difficulty)
        }
    }
}
