import SwiftUI

/// A payoff strategy as a choice, with the interest it would cost or save.
///
/// Changing strategy is allowed, but never blind: the row states the consequence
/// before the tap.
struct StrategyOptionRow: View {
    let strategy: PayoffStrategy
    let isSelected: Bool
    /// Positive means this strategy pays less interest than the current one.
    let interestDifference: Money
    let money: MoneyFormatting
    let currency: CurrencyCode
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .top, spacing: Layout.gap) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 18))
                    .foregroundStyle(isSelected ? Palette.accent : Palette.tertiaryText)

                VStack(alignment: .leading, spacing: 2) {
                    Text(strategy.label)
                        .font(Typography.label)
                        .foregroundStyle(Palette.primaryText)

                    Text(strategy.explanation)
                        .font(Typography.caption)
                        .foregroundStyle(Palette.tertiaryText)
                        .fixedSize(horizontal: false, vertical: true)

                    if !isSelected, interestDifference != 0 {
                        Text(differenceLine)
                            .font(Typography.caption.weight(.medium))
                            .foregroundStyle(interestDifference > 0 ? Palette.positive : Palette.caution)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.vertical, Layout.tightGap)
        }
        .buttonStyle(.plain)
    }

    private var differenceLine: String {
        let amount = money.string(abs(interestDifference), currency: currency)
        return interestDifference > 0 ? "Pagarías \(amount) menos en intereses" : "Pagarías \(amount) más en intereses"
    }
}
