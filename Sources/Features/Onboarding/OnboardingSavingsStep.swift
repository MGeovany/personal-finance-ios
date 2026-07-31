import SwiftUI

/// What the user already has put aside.
///
/// One question instead of the two the app actually needs. Asking separately for an
/// emergency fund and for other savings assumes the user has already divided their
/// money that way, and most have not. They have one number. The split is made here,
/// by treating the first three months of expenses as the cushion, and it is shown so
/// nothing is decided behind their back.
struct OnboardingSavingsStep: View {
    @Bindable var model: OnboardingViewModel

    @Environment(\.moneyFormatter) private var money
    /// Separates "said they have nothing" from "has not answered yet", which look
    /// the same in the numbers but should not look the same on screen.
    @State private var hasAnswered = false

    var body: some View {
        ChoiceStack {
            ChoiceCard(
                title: "No tengo nada ahorrado",
                detail: "Es un punto de partida como cualquier otro.",
                icon: "circle.slash",
                isSelected: hasAnswered && total == 0
            ) {
                hasAnswered = true
                model.draft.emergencyFund = 0
                model.draft.savings = 0
                model.advanceAfterAnswer()
            }

            AmountChoices(
                options: options,
                amount: totalBinding,
                currency: model.draft.currency,
                customTitle: "Otra cantidad",
                customPlaceholder: "Lo que tienes guardado",
                onPick: { model.advanceAfterAnswer() }
            )

            if total > 0 {
                split
            }
        }
        .animation(DesignSystem.Motion.swap, value: total)
    }

    /// Savings expressed as months of what the user has committed, because that is
    /// the unit that means something: a cushion is not an amount, it is time.
    private var options: [AmountChoice] {
        let monthly = monthlyOutgoings
        guard monthly > 0 else {
            return AmountBands.shares(
                [("Poco", 0.5), ("Un mes de sueldo", 1), ("Tres meses", 3)],
                of: model.draft.primaryIncome,
                currency: model.draft.currency
            )
        }

        return [(label: "Como un mes de gastos", months: 1.0),
                (label: "Unos tres meses", months: 3.0),
                (label: "Seis meses o más", months: 6.0)]
            .map { entry in
                AmountChoice(
                    label: entry.label,
                    amount: AmountBands.rounded(monthly.scaled(by: entry.months), currency: model.draft.currency)
                )
            }
    }

    /// How the amount will be read: the cushion first, anything above it as
    /// ammunition against expensive debt.
    private var split: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: Layout.gap) {
                DetailRow(
                    label: "Fondo de emergencia",
                    value: money.string(model.draft.emergencyFund, currency: model.draft.currency)
                )
                DetailRow(
                    label: "Ahorros disponibles",
                    value: money.string(model.draft.savings, currency: model.draft.currency)
                )
                Text("Nunca vamos a recomendarte quedarte sin colchón. Si una deuda tiene intereses muy altos, te mostramos cuánto ganarías abonando parte de tus ahorros, y tú decides.")
                    .font(Typography.caption)
                    .foregroundStyle(Palette.tertiaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private var monthlyOutgoings: Money {
        model.draft.totalCommitted + model.draft.declaredLifestyle
    }

    private var total: Money {
        model.draft.emergencyFund + model.draft.savings
    }

    /// Writes one number and splits it, so the step can ask a single question.
    private var totalBinding: Binding<Money> {
        Binding(
            get: { total },
            set: { amount in
                hasAnswered = true
                let cushion = AmountBands.rounded(
                    monthlyOutgoings.scaled(by: 3),
                    currency: model.draft.currency
                )
                model.draft.emergencyFund = min(amount, cushion)
                model.draft.savings = (amount - cushion).nonNegative
            }
        )
    }
}
