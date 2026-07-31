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

        /// A fixed expense is the same amount on the same schedule every month, so the
        /// day it leaves changes nothing the plan calculates. Asking for it only adds
        /// a field. Subscriptions are name + price; the rest defaults to monthly.
        var asksForDay: Bool { self == .income || self == .utility }

        /// `MoneyField` already lets any amount be typed in a second currency, so a
        /// separate currency row is only worth its space for income and utilities.
        var asksForCurrency: Bool { self == .income || self == .utility }

        /// Frequency only matters when the amount is not already assumed monthly.
        var asksForFrequency: Bool { self != .subscription }

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

            if purpose.asksForFrequency || purpose.asksForCurrency || purpose.asksForDay {
                CardSection {
                    if purpose.asksForFrequency {
                        SelectRow(
                            title: "Frecuencia",
                            selection: $draft.frequency,
                            options: ChargeFrequency.allCases,
                            label: \.label
                        )
                    }

                    if purpose.asksForCurrency {
                        if purpose.asksForFrequency { RowDivider() }
                        SelectRow(
                            title: "Moneda",
                            selection: $draft.currency,
                            options: currencies,
                            label: { $0.rawValue },
                            detail: { $0.displayName }
                        )
                    }

                    if purpose.asksForDay {
                        if purpose.asksForFrequency || purpose.asksForCurrency { RowDivider() }
                        DayOfMonthPicker(title: purpose.dayLabel, day: $draft.day)
                    }
                }
            }
        }
        .modalPresentation()
    }
}
