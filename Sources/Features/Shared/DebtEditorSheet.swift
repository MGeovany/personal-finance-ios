import SwiftUI

/// One editor for debts, used by onboarding and by the debt screen.
struct DebtEditorSheet: View {
    @State var draft: DebtDraft
    let currencies: [CurrencyCode]
    var showsStatus: Bool = false
    let onSave: (DebtDraft) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Nombre", text: $draft.name)
                    TextField("Institución", text: $draft.institution)
                    Picker("Tipo", selection: $draft.kind) {
                        ForEach(DebtKind.allCases) { kind in
                            Label(kind.label, systemImage: kind.icon).tag(kind)
                        }
                    }
                }

                Section {
                    MoneyField(title: "Saldo actual", amount: $draft.balance, currency: draft.currency)
                    Picker("Moneda", selection: $draft.currency) {
                        ForEach(currencies) { currency in
                            Text("\(currency.rawValue) · \(currency.symbol)").tag(currency)
                        }
                    }
                    if draft.kind.isRevolving {
                        MoneyField(title: "Límite", amount: $draft.creditLimit, currency: draft.currency)
                    }
                }

                Section {
                    PercentField(title: "Tasa de interés anual", percent: $draft.annualRatePercent)
                    MoneyField(title: "Pago mínimo", amount: $draft.minimumPayment, currency: draft.currency)
                } footer: {
                    Text("La tasa decide el orden de ataque en el plan de avalancha. Si no la sabes, revisa tu estado de cuenta.")
                }

                Section {
                    if draft.kind.isRevolving {
                        DayOfMonthPicker(title: "Fecha de corte", day: $draft.statementDay)
                    }
                    DayOfMonthPicker(title: "Fecha máxima de pago", day: $draft.dueDay)
                }

                if showsStatus {
                    Section {
                        Picker("Estado", selection: $draft.status) {
                            ForEach(DebtStatus.allCases) { status in
                                Text(status.label).tag(status)
                            }
                        }
                    } footer: {
                        Text("«No utilizar» y «Pagar y cancelar» mantienen la deuda en el plan, pero te recuerdan no gastar en ella.")
                    }
                }
            }
            .navigationTitle(draft.name.isEmpty ? "Nueva deuda" : draft.name)
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

/// Percentage input, kept separate because a rate is not money and should not
/// carry a currency symbol.
struct PercentField: View {
    let title: String
    @Binding var percent: Double

    @State private var text: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.tightGap) {
            Text(title)
                .font(Typography.label)
                .foregroundStyle(Palette.secondaryText)

            HStack {
                TextField("0", text: $text)
                    .font(Typography.amount)
                    .keyboardType(.decimalPad)
                    .onChange(of: text) { _, newValue in
                        percent = Double(newValue.replacingOccurrences(of: ",", with: ".")) ?? 0
                    }
                Text("%").foregroundStyle(Palette.tertiaryText)
            }
            .padding(.horizontal, Layout.gap)
            .padding(.vertical, 10)
            .background(Palette.surfaceMuted, in: RoundedRectangle(cornerRadius: Layout.chipRadius, style: .continuous))
        }
        .onAppear { text = percent > 0 ? trimmed(percent) : "" }
    }

    private func trimmed(_ value: Double) -> String {
        value == value.rounded() ? String(Int(value)) : String(value)
    }
}
