import SwiftUI

/// The monthly close: the full picture, and plan versus reality.
struct MonthlyCloseSheet: View {
    let dependencies: AppDependencies
    @State private var model: PeriodCloseViewModel
    @Environment(\.dismiss) private var dismiss

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        self._model = State(initialValue: PeriodCloseViewModel.make(kind: .monthly, dependencies: dependencies))
    }

    var body: some View {
        ModalScaffold(
            title: "Cierre mensual",
            primary: ModalAction("Cerrar el mes") {
                model.complete()
                dismiss()
            },
            spacing: Layout.gap
        ) {
            flowCard
            debtCard
            planCard

            if model.surplus > 0 {
                SurplusDestinationPicker(
                    surplus: model.surplus,
                    selection: $model.surplusDestination,
                    money: dependencies.money,
                    currency: model.currency
                )
            }
        }
        .modalPresentation()
    }

    private var flowCard: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: Layout.gap) {
                SectionHeader(title: "Este mes")
                DetailRow(label: "Ingresos", value: format(model.income))
                RowDivider()
                DetailRow(label: "Gastos fijos", value: format(model.fixedCosts))
                DetailRow(label: "Servicios", value: format(model.utilities))
                DetailRow(label: "Suscripciones", value: format(model.subscriptions))
                DetailRow(label: "Gastos variables", value: format(model.variableSpending))
                DetailRow(label: "Metas", value: format(model.goalFunding))
                RowDivider()
                DetailRow(label: "Fondo de emergencia", value: format(model.emergencyFund))
            }
        }
    }

    private var debtCard: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: Layout.gap) {
                SectionHeader(title: "Deuda")
                DetailRow(label: "Pagos a deuda", value: format(model.totalPaid))
                DetailRow(label: "Intereses del mes", value: format(model.interestThisMonth), tint: Palette.caution)
                RowDivider()
                DetailRow(
                    label: model.debtChange >= 0 ? "La deuda bajó" : "La deuda subió",
                    value: format(abs(model.debtChange)),
                    tint: model.debtChange >= 0 ? Palette.positive : Palette.caution
                )
                DetailRow(
                    label: "Deuda total",
                    value: format(dependencies.planStore.snapshot.totalDebt),
                    tint: Palette.debt
                )
            }
        }
    }

    /// Compares what the plan asked for with what actually happened.
    private var planCard: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: Layout.gap) {
                SectionHeader(title: "Plan \(model.plan.name)")
                DetailRow(label: "Pago recomendado", value: format(model.plan.monthlyDebtPayment))
                DetailRow(label: "Pago realizado", value: format(model.totalPaid))
                DetailRow(
                    label: "Presupuesto variable",
                    value: "\(format(model.variableSpending)) de \(format(model.plan.monthlyVariableBudget))"
                )
                RowDivider()
                DetailRow(
                    label: "Fecha estimada",
                    value: model.estimatedDate.map { dependencies.dates.dayAndMonth($0, relativeTo: Date()) } ?? "···",
                    tint: Palette.accent
                )

                if !model.overspentCategories.isEmpty {
                    Text("Se pasaron del plan: \(model.overspentCategories.map(\.categoryName).joined(separator: ", ")).")
                        .font(Typography.caption)
                        .foregroundStyle(Palette.tertiaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func format(_ value: Money) -> String {
        dependencies.money.string(value, currency: model.currency)
    }
}
