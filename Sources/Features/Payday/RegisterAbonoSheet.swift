import SwiftUI

/// Registers the payday movements, one after another.
///
/// Opens on whatever the plan is still waiting for, with the amount already filled in.
/// Saving advances to the next one rather than closing, so working through the checklist
/// never means reopening the same sheet five times.
struct RegisterAbonoSheet: View {
    let dependencies: AppDependencies
    @State private var model: RegisterAbonoViewModel
    @Environment(\.dismiss) private var dismiss

    init(dependencies: AppDependencies, instructions: [PaydayInstruction]) {
        self.dependencies = dependencies
        self._model = State(
            initialValue: RegisterAbonoViewModel(
                instructions: instructions,
                debts: dependencies.debts,
                savings: dependencies.savings,
                goals: dependencies.goals,
                planStore: dependencies.planStore
            )
        )
    }

    var body: some View {
        ModalScaffold(title: title, primary: primaryAction) {
            if let current = model.current {
                form(for: current)
            } else {
                finished
            }
        }
        .modalPresentation()
        // Fires on every save, since the count of registered movements is what changes.
        .confetti(trigger: model.progress.done)
    }

    private var title: String {
        model.isFinished ? "Todo registrado" : "Registrar abono"
    }

    private var primaryAction: ModalAction {
        if model.isFinished {
            return ModalAction("Listo") { dismiss() }
        }
        return ModalAction("Guardar", isEnabled: model.canSave) {
            // Staying open on the next movement is the point: closing after each one
            // turns a five item list into five trips through the same sheet.
            let hasMore = model.save()
            if !hasMore { return }
        }
    }

    // MARK: - The current movement

    @ViewBuilder
    private func form(for current: PaydayInstruction) -> some View {
        if let saved = model.lastSaved {
            CardSection {
                DetailRow(
                    label: saved.label,
                    value: "Registrado",
                    tint: Palette.positive,
                    icon: "checkmark.circle.fill"
                )
            }
        }

        CardSection(header: "\(model.progress.done) de \(model.progress.total) registrados") {
            DetailRow(
                label: current.label,
                value: current.value,
                tint: Palette.primaryText,
                icon: current.icon,
                caption: current.caption
            )
        }

        CardSection(footer: amountFooter(for: current)) {
            MoneyField(
                title: "Cuánto vas a registrar",
                amount: amountBinding,
                currency: model.currency
            )
            RowDivider()
            DateRow(title: "Fecha", date: $model.date)
        }

        if model.pending.count > 1 {
            CardSection(header: "Lo que sigue") {
                ForEach(model.pending.dropFirst()) { instruction in
                    OptionRow(
                        title: instruction.label,
                        detail: instruction.value,
                        icon: instruction.icon
                    ) {
                        model.select(instruction)
                    }
                }
            }
        }
    }

    /// Clamped on the way in, so an amount over the ceiling cannot be typed at all rather
    /// than being typed and then rejected on save.
    private var amountBinding: Binding<Money> {
        Binding(
            get: { model.amount },
            set: { typed in
                model.amount = model.maximum.map { limit in min(typed, limit) } ?? typed
            }
        )
    }

    private func amountFooter(for current: PaydayInstruction) -> String? {
        if let maximum = model.maximum, maximum <= current.amount {
            return "Es todo lo que queda de \(current.label.lowercased()), así que no puedes registrar más que eso."
        }
        if model.exceedsPlanned {
            return "Es más de lo que pedía el plan. Adelanta tu fecha, así que adelante."
        }
        return nil
    }

    // MARK: - Done

    private var finished: some View {
        CardSection {
            VStack(alignment: .leading, spacing: DesignSystem.Space.s) {
                Text("Registraste todo lo que el plan pedía este día de pago.")
                    .font(Typography.bodyStrong)
                    .foregroundStyle(Palette.primaryText)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Tu fecha libre de deuda ya está recalculada con estos movimientos.")
                    .font(Typography.caption)
                    .foregroundStyle(Palette.tertiaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
