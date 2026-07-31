import SwiftUI

/// A debt shown the way a physical card looks: bank, product name, and what is owed.
///
/// Numbers on a list row are easy to skim past. A card shape makes each obligation
/// feel like the thing in the wallet, which is what the user is trying to clear.
struct CreditCardVisual: View {
    let bank: String
    let cardName: String
    let balance: Money
    var ratePercent: Double?
    var currency: CurrencyCode = .hnl
    var onTap: (() -> Void)?

    @Environment(\.moneyFormatter) private var money

    var body: some View {
        Button {
            onTap?()
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(bank.isEmpty ? "Banco" : bank.uppercased())
                            .font(Typography.text(13, .bold))
                            .foregroundStyle(Palette.primaryText)
                            .tracking(0.6)

                        Text(cardName.isEmpty ? "Tarjeta de crédito" : cardName)
                            .font(Typography.caption)
                            .foregroundStyle(Palette.secondaryText)
                            .lineLimit(1)
                    }

                    Spacer(minLength: DesignSystem.Space.s)

                    Image(systemName: "wave.3.right")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Palette.tertiaryText)
                }

                Spacer(minLength: DesignSystem.Space.l)

                Text(money.string(balance, currency: currency))
                    .font(Typography.display(28, .displaySemibold))
                    .foregroundStyle(Palette.primaryText)
                    .contentTransition(.numericText())
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)

                Spacer(minLength: DesignSystem.Space.m)

                HStack(alignment: .bottom) {
                    Text("Saldo actual")
                        .font(Typography.caption)
                        .foregroundStyle(Palette.tertiaryText)

                    Spacer()

                    if let ratePercent, ratePercent > 0 {
                        Text("\(Int(ratePercent))% anual")
                            .font(Typography.captionStrong)
                            .foregroundStyle(Palette.secondaryText)
                    }
                }
            }
            .padding(DesignSystem.Space.xl)
            .frame(maxWidth: .infinity, minHeight: 168, alignment: .leading)
            .background { cardFace }
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.7), lineWidth: 1)
            }
            .softShadow(.floating)
        }
        .buttonStyle(.plain)
        .disabled(onTap == nil)
    }

    /// Soft iridescence over white. Enough to read as plastic, not a form card.
    private var cardFace: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white)

            LinearGradient(
                colors: [
                    Color(red: 0.82, green: 0.90, blue: 0.98).opacity(0.55),
                    Color(red: 0.96, green: 0.88, blue: 0.94).opacity(0.45),
                    Color(red: 0.98, green: 0.94, blue: 0.82).opacity(0.40),
                    Color.white.opacity(0.2),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}
