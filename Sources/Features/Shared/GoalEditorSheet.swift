import SwiftUI

/// One editor for goals.
///
/// The mode picker carries its own explanation, because choosing "en paralelo"
/// over "pausada" is exactly the kind of decision the app exists to make legible.
struct GoalEditorSheet: View {
    @State var draft: GoalDraft
    let currencies: [CurrencyCode]
    let onSave: (GoalDraft) -> Void

    @State private var hasDeadline: Bool
    @Environment(\.dismiss) private var dismiss

    init(draft: GoalDraft, currencies: [CurrencyCode], onSave: @escaping (GoalDraft) -> Void) {
        self._draft = State(initialValue: draft)
        self.currencies = currencies
        self.onSave = onSave
        self._hasDeadline = State(initialValue: draft.targetDate != nil)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Tipo", selection: templateBinding) {
                        ForEach(GoalTemplate.allCases) { template in
                            Label(template.label, systemImage: template.icon).tag(template)
                        }
                    }
                    TextField("Nombre", text: $draft.name)
                }

                Section {
                    MoneyField(title: "Monto objetivo", amount: $draft.targetAmount, currency: draft.currency)
                    MoneyField(title: "Ya tengo acumulado", amount: $draft.savedAmount, currency: draft.currency)
                    MoneyField(title: "Aporte mensual deseado", amount: $draft.requestedMonthly, currency: draft.currency)
                    Picker("Moneda", selection: $draft.currency) {
                        ForEach(currencies) { currency in
                            Text("\(currency.rawValue) · \(currency.symbol)").tag(currency)
                        }
                    }
                }

                Section {
                    Toggle("Tiene fecha", isOn: $hasDeadline)
                    if hasDeadline {
                        DatePicker(
                            "Fecha",
                            selection: Binding(
                                get: { draft.targetDate ?? Date() },
                                set: { draft.targetDate = $0 }
                            ),
                            displayedComponents: .date
                        )
                    }
                }
                .onChange(of: hasDeadline) { _, enabled in
                    draft.targetDate = enabled ? (draft.targetDate ?? Date()) : nil
                }

                Section {
                    Picker("Ritmo", selection: $draft.mode) {
                        ForEach(GoalMode.allCases) { mode in
                            Text(mode.label).tag(mode)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                } header: {
                    Text("¿Cómo quieres financiarla?")
                } footer: {
                    Text(draft.mode.explanation)
                }
            }
            .navigationTitle(draft.name.isEmpty ? "Nueva meta" : draft.name)
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

    /// Picking a template fills in the icon and, while the name is still untouched,
    /// the name too.
    private var templateBinding: Binding<GoalTemplate> {
        Binding(
            get: { GoalTemplate.allCases.first { $0.icon == draft.icon } ?? .custom },
            set: { template in
                draft.icon = template.icon
                if draft.name.isEmpty || GoalTemplate.allCases.contains(where: { $0.label == draft.name }) {
                    draft.name = template == .custom ? "" : template.label
                }
            }
        )
    }
}
