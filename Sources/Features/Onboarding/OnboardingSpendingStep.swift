import SwiftUI

/// One everyday category, answered by picking the amount that sounds right.
///
/// Nobody knows what they spend on groceries. Asked for a number they invent one,
/// and it is usually low by a third. Asked to choose between four amounts that are
/// each a plausible share of what they earn, they pick the one that matches their
/// life. Which is both easier and more honest. The app says outright that it will
/// correct the figure from real spending, so the answer carries no weight it cannot
/// bear.
struct OnboardingSpendingStep: View {
    @Bindable var model: OnboardingViewModel
    let category: Category

    enum Category {
        case groceries, transport, outings

        var key: String {
            switch self {
            case .groceries: CategoryKeys.groceries
            case .transport: CategoryKeys.transport
            case .outings: CategoryKeys.outings
            }
        }

        /// Shares of monthly income, with the labels a person would use for them.
        var bands: [(label: String, share: Double)] {
            switch self {
            case .groceries:
                [
                    ("Cocino poco", 0.08),
                    ("Lo normal", 0.14),
                    ("Somos varios en casa", 0.22),
                    ("Se me va bastante", 0.30),
                ]
            case .transport:
                [
                    ("Trabajo desde casa", 0.0),
                    ("Camino o me llevan", 0.02),
                    ("Bus y Uber de vez en cuando", 0.06),
                    ("Uber casi diario", 0.12),
                    ("Tengo carro", 0.18),
                ]
            case .outings:
                [
                    ("Casi nunca salgo", 0.03),
                    ("Un fin de semana al mes", 0.07),
                    ("Cada fin de semana", 0.14),
                    ("Salgo bastante", 0.22),
                ]
            }
        }

        /// Groceries has a follow-up question, so it waits for Continue instead of
        /// moving on the moment an amount is picked.
        var hasFollowUp: Bool { self == .groceries }
    }

    var body: some View {
        ChoiceStack {
            AmountChoices(
                options: options,
                amount: binding,
                currency: model.draft.currency,
                customTitle: "Otra cantidad",
                customPlaceholder: "Al mes",
                onPick: category.hasFollowUp ? nil : { model.advanceAfterAnswer() }
            )

            if category.hasFollowUp, binding.wrappedValue > 0 {
                groceryMode
            }
        }
    }

    private var options: [AmountChoice] {
        AmountBands.shares(category.bands, of: model.draft.primaryIncome, currency: model.draft.currency)
    }

    /// How the household actually shops, which decides whether the budget is one
    /// weekly limit or a big monthly trip plus top-ups.
    private var groceryMode: some View {
        CardSection(
            header: "¿Cómo compras?",
            footer: model.draft.groceryMode.explanation
        ) {
            ForEach(GroceryMode.allCases) { mode in
                OptionRow(
                    title: label(for: mode),
                    isSelected: model.draft.groceryMode == mode
                ) {
                    model.draft.groceryMode = mode
                }
            }
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private func label(for mode: GroceryMode) -> String {
        switch mode {
        case .hybrid: "Una compra grande y reposiciones"
        default: mode.label
        }
    }

    private var binding: Binding<Money> {
        Binding(
            get: { model.baseline(for: category.key) },
            set: { model.setBaseline($0, for: category.key) }
        )
    }
}
