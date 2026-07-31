import SwiftUI

/// The one number the plan cannot be built without.
///
/// A single field: the total monthly income after deductions. Later questions
/// derive their sense of scale from this, so it has to be a real figure rather than
/// a band.
struct OnboardingIncomeStep: View {
    @Bindable var model: OnboardingViewModel

    var body: some View {
        ChoiceStack {
            CardContainer {
                MoneyField(
                    title: "Ingreso total mensual",
                    amount: $model.draft.primaryIncome,
                    currency: model.draft.currency
                )
            }
        }
    }
}
