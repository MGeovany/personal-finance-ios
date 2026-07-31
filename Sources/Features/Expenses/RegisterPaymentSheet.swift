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
        ModalScaffold(
            title: "Registrar pago",
            primary: ModalAction("Guardar", isEnabled: model.canSave) {
                model.save()
                if model.clearedDebt == nil { dismiss() }
            }
        ) {
            CardSection(footer: balanceCaption) {
                if model.payableDebts.isEmpty {
                    Text("No tienes deudas pendientes.")
                        .font(Typography.body)
                        .foregroundStyle(Palette.secondaryText)
                } else {
                    SelectRow(
                        title: "Deuda",
                        selection: $model.selectedDebtID,
                        options: model.payableDebts.map { Optional($0.uuid) },
                        label: { id in model.payableDebts.first { $0.uuid == id }?.name ?? "Elegir" }
                    )
                    RowDivider()
                }

                MoneyField(title: "Monto", amount: $model.amount, currency: model.currency)
                RowDivider()
                DateRow(title: "Fecha", date: $model.date)
            }

            if model.isRecommendedAmount {
                InfoBanner(
                    message: "Es el pago que recomienda tu plan.",
                    severity: .info,
                    icon: "checkmark.seal"
                )
            }

            if let impact = model.projectedImpact, impact.movesDate {
                CardSection(header: "Con este pago") {
                    ImpactBadge(
                        impact: impact,
                        dates: dependencies.dates,
                        showsInterest: true,
                        currency: model.currency,
                        money: dependencies.money
                    )
                }
            }

            CardSection {
                CeroTextField(title: "Nota", text: $model.note, placeholder: "Opcional")
            }
        }
        .modalPresentation()
        .overlay {
            if let cleared = model.clearedDebt {
                celebration(for: cleared)
            }
        }
    }

    private var balanceCaption: String? {
        guard let debt = model.selectedDebt else { return nil }
        let balance = dependencies.money.string(debt.balance, currency: debt.currency)
        let minimum = dependencies.money.string(debt.minimumPayment, currency: debt.currency)
        return "Saldo actual: \(balance) · Mínimo: \(minimum)"
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
