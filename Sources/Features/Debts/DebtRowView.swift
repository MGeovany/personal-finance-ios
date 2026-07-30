import SwiftUI

/// A debt in the list: balance, rate, the payment it should get, and when it ends.
struct DebtRowView: View {
    let debt: DebtEntity
    let isTarget: Bool
    let recommendedPayment: Money
    let payoffDate: Date?
    let money: MoneyFormatting
    let dates: PlanDateFormatting
    let currency: CurrencyCode

    var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: Layout.gap) {
                header

                if debt.balance > 0 {
                    if let utilization = utilizationFraction {
                        ProgressBarView(fraction: utilization, tint: Palette.debt)
                    }

                    HStack(spacing: Layout.gap) {
                        StatTile(
                            label: "Pago recomendado",
                            value: money.string(recommendedPayment, currency: debt.currency),
                            tint: isTarget ? Palette.accent : Palette.primaryText,
                            size: .small
                        )
                        StatTile(
                            label: "Queda en cero",
                            value: payoffDate.map { dates.dayAndMonth($0, relativeTo: Date()) } ?? "—",
                            size: .small
                        )
                    }

                    if let available = debt.availableCredit {
                        Text("Crédito disponible: \(money.string(available, currency: debt.currency)). No es dinero tuyo.")
                            .font(Typography.caption)
                            .foregroundStyle(Palette.tertiaryText)
                    }
                }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: Layout.gap) {
            Image(systemName: debt.kind.icon)
                .font(.system(size: 18))
                .foregroundStyle(Palette.debt)
                .frame(width: 26)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: Layout.tightGap) {
                    Text(debt.name)
                        .font(Typography.label)
                        .foregroundStyle(Palette.primaryText)
                    if isTarget {
                        Chip(text: "Atacando", tint: Palette.accent, icon: "target")
                    }
                }

                Text(subtitle)
                    .font(Typography.caption)
                    .foregroundStyle(Palette.tertiaryText)

                if debt.status != .active {
                    Chip(text: debt.status.label, tint: statusTint)
                }
            }

            Spacer(minLength: Layout.tightGap)

            Text(money.string(debt.balance, currency: debt.currency))
                .font(Typography.amount)
                .foregroundStyle(debt.balance > 0 ? Palette.primaryText : Palette.positive)
        }
    }

    private var subtitle: String {
        var parts: [String] = []
        if !debt.institution.isEmpty { parts.append(debt.institution) }
        if debt.annualRate > 0 { parts.append("\(Int((debt.annualRate * 100).rounded()))% anual") }
        if let dueDay = debt.dueDay { parts.append("paga el \(dueDay)") }
        return parts.isEmpty ? debt.kind.label : parts.joined(separator: " · ")
    }

    private var utilizationFraction: Double? {
        guard let limit = debt.creditLimit, limit > 0 else { return nil }
        return min(1, (debt.balance / limit).doubleValue)
    }

    private var statusTint: Color {
        switch debt.status {
        case .paid, .closed: Palette.positive
        case .doNotUse, .payAndClose, .pendingClosure: Palette.caution
        default: Palette.secondaryText
        }
    }
}
