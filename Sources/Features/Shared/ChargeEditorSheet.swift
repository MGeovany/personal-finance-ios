import SwiftUI

/// One editor for every recurring amount in the app.
///
/// It knows nothing about storage: it hands back a draft and the caller decides
/// whether that becomes a utility, a subscription or a fixed expense.
struct ChargeEditorSheet: View {
    enum Purpose {
        case income, fixedExpense, utility, subscription

        var title: String {
            switch self {
            case .income: "Ingreso"
            case .fixedExpense: "Gasto fijo"
            case .utility: "Servicio"
            case .subscription: "Suscripción"
            }
        }

        var amountLabel: String {
            switch self {
            case .income: "Monto"
            case .fixedExpense: "Monto"
            // Utilities vary month to month, so what is stored is an estimate the
            // app reserves and later reconciles against the real bill.
            case .utility: "Monto estimado"
            case .subscription: "Precio"
            }
        }

        var dayLabel: String {
            switch self {
            case .income: "Día que lo recibes"
            case .fixedExpense, .utility: "Día de pago"
            case .subscription: "Día de cobro"
            }
        }

        var namePlaceholder: String {
            switch self {
            case .income: "Trabajo por cuenta propia"
            case .fixedExpense: "Alquiler"
            case .utility: "Luz"
            case .subscription: "Netflix"
            }
        }
    }

    let purpose: Purpose
    @State var draft: ChargeDraft
    let currencies: [CurrencyCode]
    let onSave: (ChargeDraft) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ModalScaffold(
            title: purpose.title,
            primary: ModalAction("Guardar", isEnabled: draft.isValid) {
                onSave(draft)
                dismiss()
            }
        ) {
            CardSection {
                CeroTextField(title: "Nombre", text: $draft.name, placeholder: purpose.namePlaceholder)
                MoneyField(title: purpose.amountLabel, amount: $draft.amount, currency: draft.currency)
            }

            CardSection {
                SelectRow(
                    title: "Frecuencia",
                    selection: $draft.frequency,
                    options: ChargeFrequency.allCases,
                    label: \.label
                )
                RowDivider()
                SelectRow(
                    title: "Moneda",
                    selection: $draft.currency,
                    options: currencies,
                    label: { $0.rawValue },
                    detail: { $0.displayName }
                )
                RowDivider()
                DayOfMonthPicker(title: purpose.dayLabel, day: $draft.day)
            }

            if purpose == .subscription {
                CardSection(
                    footer: "Si la marcas como no necesaria, la app te mostrará cuánto adelantarías tu fecha libre de deuda al cancelarla."
                ) {
                    CeroToggle(title: "La sigo usando", isOn: $draft.isNecessary)
                }
            }
        }
        .modalPresentation()
    }
}
