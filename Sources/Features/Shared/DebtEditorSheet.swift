import SwiftUI

/// One editor for debts, used by onboarding and by the debt screen.
struct DebtEditorSheet: View {
    @State var draft: DebtDraft
    let currencies: [CurrencyCode]
    var showsStatus: Bool = false
    let onSave: (DebtDraft) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ModalScaffold(
            title: draft.name.isEmpty ? "Nueva deuda" : draft.name,
            primary: ModalAction("Guardar", isEnabled: draft.isValid) {
                onSave(draft)
                dismiss()
            }
        ) {
            CardSection {
                CeroTextField(title: "Nombre", text: $draft.name, placeholder: "Tarjeta de crédito")
                CeroTextField(title: "Institución", text: $draft.institution, placeholder: "Banco")
                RowDivider()
                SelectRow(
                    title: "Tipo",
                    selection: $draft.kind,
                    options: DebtKind.allCases,
                    label: \.label,
                    icon: { $0.icon }
                )
            }

            CardSection {
                MoneyField(title: "Saldo actual", amount: $draft.balance, currency: draft.currency)
                if draft.kind.isRevolving {
                    MoneyField(title: "Límite", amount: $draft.creditLimit, currency: draft.currency)
                }
                RowDivider()
                SelectRow(
                    title: "Moneda de la deuda",
                    selection: $draft.currency,
                    options: currencies,
                    label: { $0.rawValue },
                    detail: { $0.displayName }
                )
            }

            CardSection(
                footer: "La tasa decide el orden de ataque en el plan de avalancha. Si no la sabes, revisa tu estado de cuenta."
            ) {
                PercentField(title: "Tasa de interés anual", percent: $draft.annualRatePercent)
                MoneyField(title: "Pago mínimo", amount: $draft.minimumPayment, currency: draft.currency)
            }

            CardSection {
                if draft.kind.isRevolving {
                    DayOfMonthPicker(title: "Fecha de corte", day: $draft.statementDay)
                    RowDivider()
                }
                DayOfMonthPicker(title: "Fecha máxima de pago", day: $draft.dueDay)
            }

            if showsStatus {
                CardSection(
                    footer: "«No utilizar» y «Pagar y cancelar» mantienen la deuda en el plan, pero te recuerdan no gastar en ella."
                ) {
                    SelectRow(
                        title: "Estado",
                        selection: $draft.status,
                        options: DebtStatus.allCases,
                        label: \.label
                    )
                }
            }
        }
        .modalPresentation()
    }
}
