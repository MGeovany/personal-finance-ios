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
        ModalScaffold(
            title: draft.name.isEmpty ? "Nueva meta" : draft.name,
            primary: ModalAction("Guardar", isEnabled: draft.isValid) {
                onSave(draft)
                dismiss()
            }
        ) {
            CardSection {
                SelectRow(
                    title: "Tipo",
                    selection: templateBinding,
                    options: GoalTemplate.allCases,
                    label: \.label,
                    icon: { $0.icon }
                )
                RowDivider()
                CeroTextField(title: "Nombre", text: $draft.name, placeholder: "Fondo de viaje")
            }

            CardSection {
                MoneyField(title: "Monto objetivo", amount: $draft.targetAmount, currency: draft.currency)
                MoneyField(title: "Ya tengo acumulado", amount: $draft.savedAmount, currency: draft.currency)
                MoneyField(title: "Aporte mensual deseado", amount: $draft.requestedMonthly, currency: draft.currency)
                RowDivider()
                SelectRow(
                    title: "Moneda",
                    selection: $draft.currency,
                    options: currencies,
                    label: { $0.rawValue },
                    detail: { $0.displayName }
                )
            }

            CardSection {
                CeroToggle(title: "Tiene fecha", isOn: $hasDeadline)
                if hasDeadline {
                    RowDivider()
                    DateRow(
                        title: "Fecha",
                        date: Binding(
                            get: { draft.targetDate ?? Date() },
                            set: { draft.targetDate = $0 }
                        )
                    )
                }
            }
            .onChange(of: hasDeadline) { _, enabled in
                draft.targetDate = enabled ? (draft.targetDate ?? Date()) : nil
            }

            CardSection(header: "¿Cómo quieres financiarla?", footer: draft.mode.explanation) {
                ForEach(GoalMode.allCases) { mode in
                    OptionRow(title: mode.label, isSelected: draft.mode == mode) {
                        withAnimation(DesignSystem.Motion.swap) { draft.mode = mode }
                    }
                }
            }
        }
        .modalPresentation()
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
