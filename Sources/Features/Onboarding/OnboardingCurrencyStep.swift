import SwiftUI

/// Which currency should be the plan's default.
///
/// The switch on every money field still lets the user type in the other one; this
/// only decides what the plan is calculated and shown in.
struct OnboardingCurrencyStep: View {
    @Bindable var model: OnboardingViewModel

    private let offered: [CurrencyCode] = [.hnl, .usd]

    var body: some View {
        ChoiceStack {
            ForEach(offered) { currency in
                ChoiceCard(
                    title: currency.displayName,
                    detail: detail(for: currency),
                    trailing: currency.rawValue,
                    isSelected: model.draft.currency == currency
                ) {
                    model.setCurrency(currency)
                    model.advanceAfterAnswer()
                }
            }
        }
    }

    private func detail(for currency: CurrencyCode) -> String {
        switch currency {
        case .usd: "Si la mayor parte de tu dinero está en dólares."
        default: "Lo más común en Honduras."
        }
    }
}
