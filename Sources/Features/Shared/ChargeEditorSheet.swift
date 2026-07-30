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
            case .subscription: "Streaming"
            }
        }
    }

    let purpose: Purpose
    @State var draft: ChargeDraft
    let currencies: [CurrencyCode]
    let onSave: (ChargeDraft) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(purpose.namePlaceholder, text: $draft.name)
                    MoneyField(title: purpose.amountLabel, amount: $draft.amount, currency: draft.currency)
                }

                Section {
                    Picker("Frecuencia", selection: $draft.frequency) {
                        ForEach(ChargeFrequency.allCases) { frequency in
                            Text(frequency.label).tag(frequency)
                        }
                    }

                    Picker("Moneda", selection: $draft.currency) {
                        ForEach(currencies) { currency in
                            Text("\(currency.rawValue) · \(currency.symbol)").tag(currency)
                        }
                    }

                    DayOfMonthPicker(title: purpose.dayLabel, day: $draft.day)
                }

                if purpose == .subscription {
                    Section {
                        Toggle("La sigo usando", isOn: $draft.isNecessary)
                    } footer: {
                        Text("Si la marcas como no necesaria, la app te mostrará cuánto adelantarías tu fecha libre de deuda al cancelarla.")
                    }
                }
            }
            .navigationTitle(purpose.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        onSave(draft)
                        dismiss()
                    }
                    .disabled(!draft.isValid)
                }
            }
        }
    }
}

/// Day-of-month selection that allows "not set", since not every charge has a
/// fixed day.
struct DayOfMonthPicker: View {
    let title: String
    @Binding var day: Int?

    var body: some View {
        Picker(title, selection: Binding(
            get: { day ?? 0 },
            set: { day = $0 == 0 ? nil : $0 }
        )) {
            Text("Sin definir").tag(0)
            ForEach(1...31, id: \.self) { value in
                Text("Día \(value)").tag(value)
            }
        }
    }
}
