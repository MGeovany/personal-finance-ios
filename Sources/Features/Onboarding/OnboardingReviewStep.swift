import SwiftUI

/// The last screen before the plans: the arithmetic, read back.
///
/// Every number here came from an answer the user gave, in the order they gave them,
/// ending with what is left. That last line is the point of the whole flow. It is
/// the first time the app tells them something they did not already know.
struct OnboardingReviewStep: View {
    let model: OnboardingViewModel
    let dependencies: AppDependencies

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.gap) {
            if !model.greetingName.isEmpty {
                Text("Listo, \(model.greetingName).")
                    .font(Typography.title)
                    .foregroundStyle(Palette.primaryText)
            }

            CardContainer {
                VStack(alignment: .leading, spacing: Layout.gap) {
                    DetailRow(label: "Ingreso mensual", value: format(model.draft.totalMonthlyIncome))

                    RowDivider()

                    if committed > 0 {
                        DetailRow(label: "Pagos fijos y servicios", value: "−" + format(committed))
                    }
                    if model.draft.declaredLifestyle > 0 {
                        DetailRow(label: "Vida diaria", value: "−" + format(model.draft.declaredLifestyle))
                    }
                    if model.draft.totalMinimumPayments > 0 {
                        DetailRow(label: "Pagos mínimos de deuda", value: "−" + format(model.draft.totalMinimumPayments))
                    }

                    RowDivider()

                    DetailRow(
                        label: "Te quedaría libre",
                        value: format(model.draft.estimatedAvailable),
                        tint: model.draft.estimatedAvailable > 0 ? Palette.positive : Palette.critical
                    )
                }
            }

            if model.draft.totalDebt > 0 {
                CardContainer {
                    StatTile(
                        label: "Debes en total",
                        value: format(model.draft.totalDebt),
                        tint: Palette.debt
                    )
                }
            }
        }
    }

    /// Everything promised before the user gets a say, minus the debt minimums,
    /// which are shown on their own line because they are the ones the plan attacks.
    private var committed: Money {
        model.draft.totalCommitted - model.draft.totalMinimumPayments
    }

    private func format(_ amount: Money) -> String {
        dependencies.money.string(amount, currency: model.draft.currency)
    }
}
