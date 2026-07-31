import SwiftUI

/// A debt in the list: name, balance, and one line of context.
///
/// Detail (recommended payment, credit left, status copy) lives in the editor.
/// The list only answers which debt, how much, and when it clears.
struct DebtRowView: View {
    let debt: DebtEntity
    let isTarget: Bool
    let recommendedPayment: Money
    let payoffDate: Date?
    let money: MoneyFormatting
    let dates: PlanDateFormatting
    /// 1-based place in the plan's attack order. Nil for settled debts.
    var attackRank: Int? = nil

    var body: some View {
        CardContainer {
            HStack(alignment: .center, spacing: DesignSystem.Space.l) {
                if let attackRank {
                    Text("\(attackRank)")
                        .font(Typography.captionStrong)
                        .foregroundStyle(isTarget ? Palette.invertedText : Palette.secondaryText)
                        .frame(width: 28, height: 28)
                        .background(
                            isTarget ? Palette.accent : Palette.surfaceMuted,
                            in: Circle()
                        )
                } else {
                    Image(systemName: debt.kind.icon)
                        .font(.system(size: 16))
                        .foregroundStyle(Palette.tertiaryText)
                        .frame(width: 28, height: 28)
                }

                VStack(alignment: .leading, spacing: DesignSystem.Space.xxs) {
                    Text(debt.name)
                        .font(Typography.label)
                        .foregroundStyle(Palette.primaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    Text(caption)
                        .font(Typography.caption)
                        .foregroundStyle(Palette.tertiaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }

                Spacer(minLength: DesignSystem.Space.s)

                VStack(alignment: .trailing, spacing: DesignSystem.Space.xxs) {
                    Text(money.string(debt.balance, currency: debt.currency))
                        .font(Typography.amount)
                        .foregroundStyle(debt.balance > 0 ? Palette.primaryText : Palette.positive)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)

                    if isTarget, debt.balance > 0 {
                        Text(money.string(recommendedPayment, currency: debt.currency))
                            .font(Typography.captionStrong)
                            .foregroundStyle(Palette.accent)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    } else if debt.status != .active {
                        Text(debt.status.label)
                            .font(Typography.caption)
                            .foregroundStyle(statusTint)
                            .lineLimit(1)
                    }
                }
                .layoutPriority(1)
            }
        }
    }

    /// Rate and freedom date, or just the kind when there is nothing else.
    private var caption: String {
        var parts: [String] = []
        if debt.annualRate > 0 {
            parts.append("\(Int((debt.annualRate * 100).rounded()))%")
        }
        if let payoffDate, debt.balance > 0 {
            parts.append(dates.dayAndMonth(payoffDate, relativeTo: Date()))
        }
        if parts.isEmpty {
            return debt.kind.label
        }
        return parts.joined(separator: " · ")
    }

    private var statusTint: Color {
        switch debt.status {
        case .paid, .closed: Palette.positive
        case .doNotUse, .payAndClose, .pendingClosure: Palette.caution
        default: Palette.secondaryText
        }
    }
}
