import SwiftUI

/// Records a payment against a debt, and celebrates when one disappears.
struct RegisterPaymentSheet: View {
    let dependencies: AppDependencies
    @State private var model: RegisterPaymentViewModel
    @Environment(\.dismiss) private var dismiss

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        self._model = State(
            initialValue: RegisterPaymentViewModel(
                debts: dependencies.debts,
                planStore: dependencies.planStore
            )
        )
    }

    var body: some View {
        NavigationStack {
            form
                .navigationTitle("Registrar pago")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancelar") { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Guardar") {
                            model.save()
                            if model.clearedDebt == nil { dismiss() }
                        }
                        .disabled(!model.canSave)
                    }
                }
                .overlay {
                    if let cleared = model.clearedDebt {
                        celebration(for: cleared)
                    }
                }
        }
    }

    private var form: some View {
        Form {
            Section {
                if model.payableDebts.isEmpty {
                    Text("No tienes deudas pendientes.")
                        .font(Typography.body)
                        .foregroundStyle(Palette.secondaryText)
                } else {
                    Picker("Deuda", selection: $model.selectedDebtID) {
                        ForEach(model.payableDebts) { debt in
                            Text(debt.name).tag(Optional(debt.uuid))
                        }
                    }
                    .pickerStyle(.navigationLink)
                }

                MoneyField(title: "Monto", amount: $model.amount, currency: model.currency)
                DatePicker("Fecha", selection: $model.date, displayedComponents: .date)
            } footer: {
                if let debt = model.selectedDebt {
                    Text("Saldo actual: \(dependencies.money.string(debt.balance, currency: debt.currency)) · Mínimo: \(dependencies.money.string(debt.minimumPayment, currency: debt.currency))")
                }
            }

            if model.isRecommendedAmount {
                Section {
                    Label("Es el pago que recomienda tu plan", systemImage: "checkmark.seal")
                        .font(Typography.caption)
                        .foregroundStyle(Palette.accent)
                }
            }

            if let impact = model.projectedImpact, impact.movesDate {
                Section {
                    ImpactBadge(
                        impact: impact,
                        dates: dependencies.dates,
                        showsInterest: true,
                        currency: model.currency,
                        money: dependencies.money
                    )
                } header: {
                    Text("Con este pago")
                }
            }

            Section {
                TextField("Nota (opcional)", text: $model.note)
            }
        }
    }

    /// The debt hit zero: acknowledge it, then ask what the account should become.
    /// The freed-up payment moves to the next debt automatically either way.
    private func celebration(for debt: DebtEntity) -> some View {
        CelebrationOverlay(
            title: "\(debt.name) quedó en cero",
            message: celebrationMessage(for: debt),
            actions: [
                CelebrationOverlay.Action(title: "Mantenerla activa") {
                    model.keepActive(debt)
                    dismiss()
                },
                CelebrationOverlay.Action(title: "Cancelarla") {
                    model.markForClosure(debt)
                    dismiss()
                },
                CelebrationOverlay.Action(title: "Usarla solo para ciertos gastos") {
                    model.restrictSpending(debt)
                    dismiss()
                },
            ],
            onDismiss: {
                model.dismissCelebration()
                dismiss()
            }
        )
    }

    private func celebrationMessage(for debt: DebtEntity) -> String {
        guard let next = model.nextDebtAfterClearing else {
            return "Ya no debes nada en esta cuenta."
        }
        let freed = dependencies.money.string(debt.minimumPayment, currency: debt.currency)
        return "Los \(freed) que pagabas aquí pasan automáticamente a \(next.name)."
    }
}
