import SwiftUI

/// Name the card, say what is owed, optionally the rate. Then keep adding more.
struct CreditCardEditorSheet: View {
    @State private var draft: DebtDraft
    let onSave: (DebtDraft) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var knowsRate: Bool

    init(draft: DebtDraft, knowsRate: Bool = false, onSave: @escaping (DebtDraft) -> Void) {
        _draft = State(initialValue: draft)
        _knowsRate = State(initialValue: knowsRate)
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
                if !knowsRate {
                    draft.annualRatePercent = DebtKind.creditCard.assumedRate
                }
                draft.kind = .creditCard
                draft.minimumPayment = draft.balance.scaled(by: DebtKind.creditCard.typicalPaymentShare).rounded
                onSave(draft)
                dismiss()
            }
        ) {
            preview

            CardSection(header: "Banco", footer: "Ej. BAC, Ficohsa, Atlántida") {
                CeroTextField(
                    title: "Nombre del banco",
                    text: $draft.institution,
                    placeholder: "BAC",
                    capitalization: .words
                )

                bankChips
            }

            CardSection(header: "Tarjeta", footer: "El nombre como aparece en el plástico o en la app del banco.") {
                CeroTextField(
                    title: "Nombre oficial",
                    text: $draft.name,
                    placeholder: suggestedCards.first ?? "BAC Visa Signature",
                    capitalization: .words
                )

                if !suggestedCards.isEmpty {
                    cardChips
                }
            }

            CardSection {
                MoneyField(
                    title: "Cantidad que debes",
                    amount: $draft.balance,
                    currency: draft.currency,
                    caption: "El saldo actual, no el límite."
                )
            }

            CardSection(
                footer: "Si no la sabes, no pasa nada. Usamos una tasa típica de Honduras y la puedes corregir después."
            ) {
                CeroToggle(title: "¿Conoces la tasa?", caption: "La del estado de cuenta, anual.", isOn: $knowsRate)

                if knowsRate {
                    PercentField(title: "Tasa de interés anual", percent: $draft.annualRatePercent)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .animation(DesignSystem.Motion.swap, value: knowsRate)
        }
        .modalPresentation()
        .onAppear {
            if draft.annualRatePercent == 0 {
                draft.annualRatePercent = DebtKind.creditCard.assumedRate
            }
        }
    }

    private var preview: some View {
        CreditCardVisual(
            bank: draft.institution,
            cardName: draft.name,
            balance: draft.balance,
            ratePercent: knowsRate ? draft.annualRatePercent : nil,
            currency: draft.currency
        )
    }

    private var bankChips: some View {
        FlexibleChipRow(
            titles: HondurasCreditCards.banks.map(\.name),
            selection: draft.institution
        ) { bank in
            draft.institution = bank
            if !HondurasCreditCards.cards(for: bank).contains(draft.name) {
                draft.name = ""
            }
        }
    }

    private var cardChips: some View {
        FlexibleChipRow(titles: suggestedCards, selection: draft.name) { card in
            draft.name = card
        }
    }
}

/// Simple wrapping row of suggestion chips under a field.
private struct FlexibleChipRow: View {
    let titles: [String]
    let selection: String
    let onPick: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Space.s) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: DesignSystem.Space.s) {
                    ForEach(row, id: \.self) { title in
                        SelectableChip(
                            text: title,
                            isSelected: selection.caseInsensitiveCompare(title) == .orderedSame
                        ) {
                            onPick(title)
                        }
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }

    /// Rough wrap: ~2 a 3 chips per row depending on label length.
    private var rows: [[String]] {
        var result: [[String]] = []
        var current: [String] = []
        var width = 0
        for title in titles {
            let cost = title.count > 12 ? 2 : 1
            if width + cost > 3, !current.isEmpty {
                result.append(current)
                current = [title]
                width = cost
            } else {
                current.append(title)
                width += cost
            }
        }
        if !current.isEmpty { result.append(current) }
        return result
    }
}
