import SwiftUI

/// What the app says back after an expense is recorded.
///
/// This screen is the app's whole thesis in miniature: the money is spent, here is
/// exactly what it cost you, and no scolding anywhere.
struct ExpenseOutcomeView: View {
    let outcome: AddExpenseViewModel.Outcome
    let categoryName: String
    let amount: Money
    let dependencies: AppDependencies
    let onAddAnother: () -> Void
    let onDone: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: Layout.gap) {
                headline

                CardContainer {
                    VStack(alignment: .leading, spacing: Layout.gap) {
                        DetailRow(
                            label: "Queda en \(categoryName.lowercased())",
                            value: format(outcome.categoryRemaining)
                        )
                        DetailRow(label: "Queda esta semana", value: format(outcome.weekRemaining))
                        DetailRow(label: "Queda este mes", value: format(outcome.monthRemaining))
                    }
                }

                if let reserved = outcome.reservedAmount {
                    InfoBanner(
                        message: "Reservamos \(format(reserved)) para pagar esa tarjeta antes de su fecha límite. Ese dinero ya no aparece como disponible.",
                        severity: .info,
                        icon: "lock"
                    )
                }

                if outcome.becameDebt {
                    InfoBanner(
                        message: "Este gasto se sumó a tu deuda porque no tenías el dinero reservado.",
                        severity: .caution
                    )
                }

                ImpactBadge(
                    impact: outcome.impact,
                    dates: dependencies.dates,
                    showsInterest: true,
                    currency: dependencies.currency,
                    money: dependencies.money
                )

                VStack(spacing: Layout.tightGap) {
                    Button("Agregar otro gasto", action: onAddAnother).secondaryButton()
                    Button("Listo", action: onDone).primaryButton()
                }
                .padding(.top, Layout.tightGap)
            }
            .padding(Layout.gutter)
        }
        .background(Palette.canvas)
    }

    private var headline: some View {
        VStack(spacing: Layout.tightGap) {
            Image(systemName: outcome.isWithinPlan ? "checkmark.circle.fill" : "info.circle.fill")
                .font(.system(size: 34))
                .foregroundStyle(outcome.isWithinPlan ? Palette.positive : Palette.caution)

            Text("Gastaste \(format(amount))")
                .font(Typography.title)
                .foregroundStyle(Palette.primaryText)

            Text(statusLine)
                .font(Typography.body)
                .foregroundStyle(Palette.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, Layout.gap)
    }

    private var statusLine: String {
        if outcome.isWithinPlan {
            return "Sigues dentro de tu plan."
        }
        return "Vas por encima de lo planeado en esta categoría. No pasa nada: aquí está el efecto."
    }

    private func format(_ value: Money) -> String {
        dependencies.money.string(value, currency: dependencies.currency)
    }
}
