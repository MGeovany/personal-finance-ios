import SwiftUI

/// Pick the bank, pick the card, say what is owed. Then keep adding more.
///
/// Both names are chosen from a list rather than typed, because a user recognises
/// their card faster than they can spell it, and a consistent name is what lets the
/// app guess the rate. Neither list is a wall: whatever is missing can be written in.
struct CreditCardEditorSheet: View {
    @State private var draft: DebtDraft
    let onSave: (DebtDraft) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.planDates) private var dates
    /// The last rate the estimator wrote. Anything else in the field came from the
    /// user, which is how the estimate knows to stop overwriting it. Comparing values
    /// rather than watching for changes keeps this true regardless of the order
    /// SwiftUI delivers updates in.
    @State private var estimatedRate: Double?

    init(draft: DebtDraft, onSave: @escaping (DebtDraft) -> Void) {
        _draft = State(initialValue: draft)
        self.onSave = onSave
    }

    private var suggestedCards: [String] {
        HondurasCreditCards.cards(for: draft.institution)
    }

    private var canSave: Bool {
        !draft.institution.trimmingCharacters(in: .whitespaces).isEmpty
            && !draft.name.trimmingCharacters(in: .whitespaces).isEmpty
            && draft.balance > 0
    }

    var body: some View {
        ModalScaffold(
            title: "Tarjeta de crédito",
            primary: ModalAction("Guardar", isEnabled: canSave) {
                draft.kind = .creditCard
                draft.minimumPayment = draft.balance.scaled(by: DebtKind.creditCard.typicalPaymentShare).rounded
                onSave(draft)
                dismiss()
            }
        ) {
            CreditCardVisual(
                bank: draft.institution,
                cardName: draft.name,
                balance: draft.balance,
                ratePercent: draft.annualRatePercent,
                currency: draft.currency
            )

            CardSection {
                SelectOrAddRow(
                    title: "Banco",
                    value: $draft.institution,
                    options: HondurasCreditCards.banks.map(\.name),
                    placeholder: "Elegir",
                    addTitle: "Mi banco no está en la lista",
                    addFieldTitle: "Nombre del banco",
                    addPlaceholder: "BAC"
                )

                RowDivider()

                SelectOrAddRow(
                    title: "Tarjeta",
                    value: $draft.name,
                    options: suggestedCards,
                    placeholder: "Elegir",
                    addTitle: "Mi tarjeta no está en la lista",
                    addFieldTitle: "Nombre de la tarjeta",
                    addPlaceholder: suggestedCards.first ?? "Visa Gold"
                )
            }

            CardSection {
                MoneyField(
                    title: "Cantidad que debes",
                    amount: $draft.balance,
                    currency: draft.currency,
                    caption: "El saldo actual, no el límite."
                )
            }

            CardSection {
                PercentField(
                    title: "Tasa de interés anual",
                    percent: $draft.annualRatePercent,
                    caption: rateCaption
                )
            }
        }
        .modalPresentation()
        .onAppear(perform: applyEstimatedRate)
        .onChange(of: draft.institution) { _, bank in
            // A suggestion from the previous bank no longer applies. Something the
            // user typed does, so it stays.
            if HondurasCreditCards.isSuggestion(draft.name),
               !HondurasCreditCards.cards(for: bank).contains(draft.name) {
                draft.name = ""
            }
        }
        .onChange(of: draft.name) { _, _ in
            applyEstimatedRate()
        }
    }

    /// Whether the number in the field is the user's rather than the estimator's.
    private var hasEditedRate: Bool {
        guard let estimatedRate else {
            // Nothing estimated yet, so an existing rate can only have come from a
            // card being edited rather than created.
            return draft.annualRatePercent > 0
        }
        return draft.annualRatePercent != estimatedRate
    }

    /// Fills the rate in from the card's tier, until the user corrects it.
    ///
    /// The field is never left empty: an estimate the user can see and change beats a
    /// blank that stalls setup while they go looking for a statement.
    private func applyEstimatedRate() {
        guard !hasEditedRate else { return }
        let estimate = CreditCardRates.estimate(forCardNamed: draft.name)
        draft.annualRatePercent = estimate.percent
        estimatedRate = estimate.percent
    }

    private var rateCaption: String {
        let estimate = CreditCardRates.estimate(forCardNamed: draft.name)
        let reviewed = dates.dayAndMonth(estimate.reviewedOn, relativeTo: Date())
        return "Tasa estimada, revisada el \(reviewed). Puede ser inexacta o haber cambiado: si tienes tu estado de cuenta, corrígela."
    }
}
