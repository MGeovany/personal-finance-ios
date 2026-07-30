import SwiftUI

/// Emergency fund and savings.
///
/// Kept separate because they play different roles: the cushion protects the plan,
/// while savings above it are ammunition against expensive debt.
struct OnboardingSavingsStep: View {
    @Bindable var model: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.gap) {
            CardContainer {
                VStack(alignment: .leading, spacing: Layout.gap) {
                    MoneyField(
                        title: "Fondo de emergencia",
                        amount: $model.draft.emergencyFund,
                        currency: model.draft.currency
                    )
                    MoneyField(
                        title: "Otros ahorros",
                        amount: $model.draft.savings,
                        currency: model.draft.currency
                    )
                }
            }

            Text("Nunca vamos a recomendarte que te quedes sin colchón. Si una deuda tiene intereses muy altos, te mostraremos cuánto ganarías abonando parte de tus ahorros, y tú decides.")
                .font(Typography.caption)
                .foregroundStyle(Palette.tertiaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
