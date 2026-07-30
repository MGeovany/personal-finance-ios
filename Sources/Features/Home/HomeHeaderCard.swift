import SwiftUI

/// The top of the dashboard: total debt, the freedom date, and the active plan.
///
/// The two numbers that matter most get the most space. Everything else on the
/// screen is detail beneath them.
struct HomeHeaderCard: View {
    let totalDebt: Money
    let debtChange: Money
    let freedomDate: Date?
    let monthsToFreedom: Int?
    let planName: String
    let money: MoneyFormatting
    let dates: PlanDateFormatting
    let currency: CurrencyCode
    let onChangePlan: () -> Void

    var body: some View {
        CardContainer(padding: Layout.gutter) {
            VStack(alignment: .leading, spacing: Layout.sectionGap) {
                debtBlock
                RowDivider()
                freedomBlock
            }
        }
    }

    private var debtBlock: some View {
        VStack(alignment: .leading, spacing: Layout.tightGap) {
            Text("Debes en total")
                .font(Typography.label)
                .foregroundStyle(Palette.secondaryText)

            Text(money.string(totalDebt, currency: currency))
                .font(Typography.hero)
                .foregroundStyle(Palette.primaryText)
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            if debtChange != 0 {
                HStack(spacing: 4) {
                    Image(systemName: debtChange > 0 ? "arrow.down" : "arrow.up")
                        .font(.system(size: 11, weight: .bold))
                    Text("\(money.string(abs(debtChange), currency: currency)) \(debtChange > 0 ? "menos" : "más") que el mes pasado")
                        .font(Typography.caption)
                }
                .foregroundStyle(debtChange > 0 ? Palette.positive : Palette.caution)
            }
        }
    }

    private var freedomBlock: some View {
        HStack(alignment: .top, spacing: Layout.gap) {
            VStack(alignment: .leading, spacing: Layout.tightGap) {
                Text("Libre de deudas")
                    .font(Typography.label)
                    .foregroundStyle(Palette.secondaryText)

                Text(freedomDate.map { dates.dayAndMonth($0, relativeTo: Date()) } ?? "Sin fecha")
                    .font(Typography.statistic)
                    .foregroundStyle(Palette.accent)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)

                Text(dates.horizon(months: monthsToFreedom))
                    .font(Typography.caption)
                    .foregroundStyle(Palette.tertiaryText)
            }

            Spacer(minLength: Layout.tightGap)

            Button(action: onChangePlan) {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Plan")
                        .font(Typography.caption)
                        .foregroundStyle(Palette.tertiaryText)
                    HStack(spacing: 3) {
                        Text(planName)
                            .font(Typography.label)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(Palette.accent)
                }
            }
            .buttonStyle(.plain)
        }
    }
}
