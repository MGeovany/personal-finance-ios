import SwiftUI

/// The next recommended payment: which debt, how much, and why that one.
struct NextPaymentCard: View {
    let debt: DebtEntity?
    let strategy: PayoffStrategy
    let recommendedPayment: Money
    let extraPayment: Money
    let minimums: Money
    let payoffDate: Date?
    let money: MoneyFormatting
    let dates: PlanDateFormatting
    let currency: CurrencyCode
    let onRegisterPayment: () -> Void

    var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: DesignSystem.Space.l) {
                SectionHeader(title: "Tu siguiente pago")

                if let debt {
                    HStack(spacing: DesignSystem.Space.l) {
                        Image(systemName: debt.kind.icon)
                            .font(.system(size: 18))
                            .foregroundStyle(Palette.debt)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(debt.name)
                                .font(Typography.label)
                                .foregroundStyle(Palette.primaryText)
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                            Text(reasonLine(for: debt))
                                .font(Typography.caption)
                                .foregroundStyle(Palette.tertiaryText)
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                        }

                        Spacer(minLength: 0)
                    }

                    RowDivider()

                    DetailRow(label: "Pagos mínimos", value: money.string(minimums, currency: currency))
                    DetailRow(
                        label: "Pago adicional sugerido",
                        value: money.string(extraPayment, currency: currency),
                        tint: Palette.accent
                    )
                    RowDivider()
                    DetailRow(
                        label: "Total este mes",
                        value: money.string(recommendedPayment, currency: currency),
                        tint: Palette.primaryText
                    )

                    if let payoffDate {
                        Text("A este ritmo, \(debt.name) queda en cero el \(dates.dayAndMonth(payoffDate)).")
                            .font(Typography.caption)
                            .foregroundStyle(Palette.tertiaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Button("Registrar pago", action: onRegisterPayment)
                        .primaryButton()
                        .padding(.top, Layout.tightGap)
                } else {
                    Text("No tienes deudas activas. Todo lo que sobra puede ir a tus metas o a tu fondo de emergencia.")
                        .font(Typography.body)
                        .foregroundStyle(Palette.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    /// Says why this debt is first, because a recommendation the user does not
    /// understand is a recommendation they will not follow.
    private func reasonLine(for debt: DebtEntity) -> String {
        switch strategy {
        case .avalanche:
            let rate = Int((debt.annualRate * 100).rounded())
            return rate > 0 ? "La tasa más alta: \(rate)% anual" : "Siguiente en tu plan"
        case .snowball:
            return "El saldo más bajo: \(money.string(debt.balance, currency: currency))"
        case .custom:
            return "La priorizaste tú"
        }
    }
}
