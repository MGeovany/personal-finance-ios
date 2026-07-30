import SwiftUI

/// How much is left to spend this week and this month.
///
/// Answers "¿cuánto puedo gastar?" — the question users open the app for most
/// often, so it sits directly under the debt total.
struct SpendingRoomCard: View {
    let week: BudgetConsumption
    let month: BudgetConsumption
    let spentToday: Money
    let money: MoneyFormatting
    let currency: CurrencyCode

    var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: Layout.gap) {
                VStack(alignment: .leading, spacing: Layout.tightGap) {
                    Text("Te queda esta semana")
                        .font(Typography.label)
                        .foregroundStyle(Palette.secondaryText)

                    Text(money.string(week.remaining, currency: currency))
                        .font(Typography.statistic)
                        .foregroundStyle(tint(for: week))
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                }

                ProgressBarView(fraction: week.usedFraction, tint: tint(for: week))

                HStack {
                    Text("Gastado \(money.string(week.spent, currency: currency)) de \(money.string(week.budget, currency: currency))")
                        .font(Typography.caption)
                        .foregroundStyle(Palette.tertiaryText)
                    Spacer()
                    if week.isOverBudget {
                        Chip(text: "Excedido", tint: Palette.caution)
                    }
                }

                RowDivider()

                DetailRow(
                    label: "Queda del mes",
                    value: money.string(month.remaining, currency: currency),
                    tint: tint(for: month)
                )
                DetailRow(
                    label: "Gastado hoy",
                    value: money.string(spentToday, currency: currency)
                )
            }
        }
    }

    /// Amber once the week is nearly spent, and when it is over — never red. Going
    /// over budget is information, not an alarm.
    private func tint(for consumption: BudgetConsumption) -> Color {
        if consumption.isOverBudget { return Palette.caution }
        if consumption.isNearLimit { return Palette.caution }
        return Palette.primaryText
    }
}
