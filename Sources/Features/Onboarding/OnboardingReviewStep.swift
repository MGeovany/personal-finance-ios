import SwiftUI

/// The last screen before the plans: what the app understood, in one card.
struct OnboardingReviewStep: View {
    let model: OnboardingViewModel
    let dependencies: AppDependencies

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.gap) {
            CardContainer {
                VStack(alignment: .leading, spacing: Layout.gap) {
                    DetailRow(label: "Ingresos mensuales", value: format(model.draft.totalMonthlyIncome))
                    RowDivider()
                    DetailRow(label: "Gastos fijos", value: format(total(model.draft.fixedExpenses)))
                    DetailRow(label: "Servicios", value: format(total(model.draft.utilities)))
                    DetailRow(label: "Suscripciones", value: format(total(model.draft.subscriptions)))
                    DetailRow(label: "Vida diaria declarada", value: format(model.draft.declaredLifestyle))
                    RowDivider()
                    DetailRow(
                        label: "Deuda total",
                        value: format(model.draft.totalDebt),
                        tint: Palette.debt
                    )
                    DetailRow(
                        label: "Pagos mínimos",
                        value: format(model.draft.debts.reduce(Money.zero) { $0 + $1.minimumPayment })
                    )
                    if !model.draft.goals.isEmpty {
                        DetailRow(label: "Metas", value: "\(model.draft.goals.count)")
                    }
                }
            }

            InfoBanner(
                message: model.draft.totalDebt > 0
                    ? "Vamos a calcular tres planes con distintas velocidades. Podrás cambiar de plan cuando quieras y ver cómo se mueve tu fecha."
                    : "No registraste deudas. Vamos a calcular tres presupuestos con distintos niveles de holgura.",
                severity: .info
            )
        }
    }

    private func total(_ charges: [ChargeDraft]) -> Money {
        charges.reduce(Money.zero) { $0 + $1.monthlyAmount }
    }

    private func format(_ amount: Money) -> String {
        dependencies.money.string(amount, currency: model.draft.currency)
    }
}
