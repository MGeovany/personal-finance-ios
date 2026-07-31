import SwiftUI

/// A card-shaped answer to a question.
///
/// Built for the setup flow, where the user should be picking rather than
/// composing: the card is large enough to hit without aiming, says what it means in
/// a sentence, and shows its own selected state so no separate confirmation is
/// needed. Selection reads as a black ring and a filled mark, which is all the
/// emphasis a monochrome interface has to give.
struct ChoiceCard: View {
    let title: String
    var detail: String?
    var icon: String?
    /// Shown on the trailing edge, for the amount or the count a choice implies.
    var trailing: String?
    var isSelected: Bool = false
    /// Off for a card that acts on a tap instead of holding an answer, which then
    /// shows a chevron rather than a selection mark.
    var showsSelection: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Layout.gap) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(isSelected ? Palette.primaryText : Palette.secondaryText)
                        .frame(width: 26)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Typography.bodyStrong)
                        .foregroundStyle(Palette.primaryText)
                        .multilineTextAlignment(.leading)

                    if let detail {
                        Text(detail)
                            .font(Typography.caption)
                            .foregroundStyle(Palette.tertiaryText)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer(minLength: Layout.tightGap)

                if let trailing {
                    Text(trailing)
                        .font(Typography.amount)
                        .foregroundStyle(Palette.primaryText)
                }

                if showsSelection {
                    SelectionMark(isSelected: isSelected)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Palette.tertiaryText)
                }
            }
            .padding(Layout.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(RoundedRectangle(cornerRadius: Layout.chipRadius, style: .continuous))
            .modifier(ChoiceGlassSurface(isSelected: isSelected, cornerRadius: Layout.chipRadius))
        }
        .buttonStyle(ChoiceButtonStyle(isSelected: isSelected))
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

/// A choice narrow enough to sit beside others in a grid: the icon above the
/// label, for answers short enough to read in one glance.
struct ChoiceTile: View {
    let title: String
    var icon: String?
    var isSelected: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: DesignSystem.Space.s) {
                HStack(alignment: .top, spacing: DesignSystem.Space.xxs) {
                    if let icon {
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(isSelected ? Palette.primaryText : Palette.secondaryText)
                    }
                    Spacer(minLength: 0)
                    SelectionMark(isSelected: isSelected, size: 20)
                }

                Text(title)
                    .font(Typography.captionStrong)
                    .foregroundStyle(Palette.primaryText)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)
            }
            .padding(Layout.gap)
            .frame(maxWidth: .infinity, minHeight: 92, alignment: .topLeading)
            // Empty space inside the tile is not hit-testable by default; without
            // this, only the icon, label and radio register a tap.
            .contentShape(RoundedRectangle(cornerRadius: Layout.chipRadius, style: .continuous))
            .modifier(ChoiceGlassSurface(isSelected: isSelected, cornerRadius: Layout.chipRadius))
        }
        .buttonStyle(ChoiceButtonStyle(isSelected: isSelected))
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

/// Liquid-glass face for a choice: system glass on iOS 26, soft lift elsewhere,
/// with a black ring when selected.
private struct ChoiceGlassSurface: ViewModifier {
    let isSelected: Bool
    let cornerRadius: CGFloat

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content
                .glassEffect(.regular.interactive(), in: shape)
                .overlay {
                    shape.strokeBorder(isSelected ? Palette.accent : .clear, lineWidth: 2)
                }
        } else {
            content
                .background(LiquidGlass.fill, in: shape)
                .overlay {
                    shape.strokeBorder(isSelected ? Palette.accent : .clear, lineWidth: 2)
                }
                .softShadow(isSelected ? .floating : .raised)
        }
    }
}

/// The mark that says a choice is the current answer.
///
/// An empty ring rather than nothing at all, so the user can see where the answer
/// will land before committing to it.
struct SelectionMark: View {
    let isSelected: Bool
    var size: CGFloat = 22

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(Palette.hairline, lineWidth: 1.5)

            Circle()
                .fill(Palette.accent)
                .scaleEffect(isSelected ? 1 : 0.1)
                .opacity(isSelected ? 1 : 0)

            Image(systemName: "checkmark")
                .font(.system(size: size * 0.45, weight: .bold))
                .foregroundStyle(Palette.invertedText)
                .scaleEffect(isSelected ? 1 : 0.4)
                .opacity(isSelected ? 1 : 0)
        }
        .frame(width: size, height: size)
        .animation(DesignSystem.Motion.tap, value: isSelected)
    }
}

/// Presses a choice into the page when tapped. Elevation itself lives on the
/// glass surface, so this style only handles the press.
private struct ChoiceButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(DesignSystem.Motion.tap, value: configuration.isPressed)
            .animation(DesignSystem.Motion.tap, value: isSelected)
    }
}

// MARK: - Amounts

/// An amount answered by picking, with typing kept as the last resort.
///
/// Setup used to open with an empty money field, which asks the user to know a
/// number they have never had to say out loud. Offering plausible amounts turns
/// that into recognition: they pick the one that sounds like their life, and only
/// reach for the keyboard when none of them do.
struct AmountChoices: View {
    let options: [AmountChoice]
    @Binding var amount: Money
    let currency: CurrencyCode
    /// Wording for the escape hatch, which differs between "how much" and
    /// "how much do you have".
    var customTitle: String = "Otra cantidad"
    var customPlaceholder: String = "Escribe el monto"
    /// Called when one of the offered amounts is picked, so a question with nothing
    /// left to ask can move on by itself. Not called for a typed amount, which the
    /// user is still in the middle of.
    var onPick: (() -> Void)?

    @Environment(\.moneyFormatter) private var money
    @State private var isCustom = false

    var body: some View {
        VStack(spacing: DesignSystem.Space.s) {
            ForEach(options) { option in
                ChoiceCard(
                    title: option.label,
                    detail: option.detail,
                    trailing: money.string(option.amount, currency: currency),
                    isSelected: !isCustom && amount == option.amount
                ) {
                    isCustom = false
                    amount = option.amount
                    onPick?()
                }
            }

            ChoiceCard(
                title: customTitle,
                icon: "pencil",
                isSelected: isCustom
            ) {
                // A preset is cleared so the field opens empty, but a number the
                // user typed before is left alone for them to correct.
                if matchedOption != nil { amount = 0 }
                isCustom = true
            }

            if isCustom {
                CardContainer {
                    MoneyField(
                        title: customPlaceholder,
                        amount: $amount,
                        currency: currency
                    )
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(DesignSystem.Motion.swap, value: isCustom)
        // An amount typed earlier, or restored on the way back, should show as the
        // option it matches rather than resetting the question.
        .onAppear { isCustom = amount > 0 && matchedOption == nil }
    }

    private var matchedOption: AmountChoice? {
        options.first { $0.amount == amount }
    }
}

/// One offered amount: what it is called, and optionally why it is being offered.
struct AmountChoice: Identifiable {
    let label: String
    var detail: String?
    let amount: Money

    var id: Money { amount }
}

/// Builds the amounts a question offers.
///
/// Every band is a share of what the user earns, so the options are plausible for
/// somebody on 12,000 a month and for somebody on 90,000 without either of them
/// being shown a list that insults them. Amounts are rounded to something a person
/// would actually say.
enum AmountBands {
    static func shares(
        _ shares: [(label: String, share: Double)],
        of income: Money,
        currency: CurrencyCode
    ) -> [AmountChoice] {
        unique(
            shares.map { entry in
                AmountChoice(
                    label: entry.label,
                    amount: rounded(income.scaled(by: entry.share), currency: currency)
                )
            }
        )
    }

    /// Fixed amounts, for bills that do not scale with salary (streaming, phone).
    static func absolute(
        _ options: [(label: String, amount: Money)],
        currency: CurrencyCode
    ) -> [AmountChoice] {
        unique(
            options.map { entry in
                AmountChoice(
                    label: entry.label,
                    amount: rounded(entry.amount, currency: currency)
                )
            }
        )
    }

    /// Drops duplicate amounts so the same number never appears twice. Zero is
    /// kept: answers like "trabajo desde casa" are a real choice, not an empty one.
    private static func unique(_ options: [AmountChoice]) -> [AmountChoice] {
        options.reduce(into: [AmountChoice]()) { result, option in
            guard option.amount >= 0, !result.contains(where: { $0.amount == option.amount }) else { return }
            result.append(option)
        }
    }

    /// Rounds to a step a person would name out loud.
    ///
    /// A band that lands on 875 reads as a calculation the app performed, which
    /// invites the user to check it. 900 reads as an option, which is what it is.
    static func rounded(_ amount: Money, currency: CurrencyCode) -> Money {
        let step = self.step(for: amount, currency: currency)
        guard step > 0 else { return amount.rounded }
        return (amount / step).rounded * step
    }

    /// Coarser as the amount grows, because precision that nobody would say out
    /// loud is precision that only looks like accuracy.
    private static func step(for amount: Money, currency: CurrencyCode) -> Money {
        if currency.isSmallDenomination {
            switch amount {
            case ..<20: return 1
            case ..<200: return 5
            default: return 25
            }
        }

        switch amount {
        case ..<1_000: return 50
        case ..<10_000: return 100
        default: return 500
        }
    }
}

extension CurrencyCode {
    /// Whether a single unit buys enough that amounts are named in tens rather than
    /// hundreds, which is what decides how coarsely a band may be rounded.
    var isSmallDenomination: Bool {
        self == .usd || self == .eur
    }
}

// MARK: - Entrance

/// Stacks choices with a short staggered fade, so a question of options arrives as
/// a list being offered rather than a wall of cards appearing at once.
struct ChoiceStack<Content: View>: View {
    @ViewBuilder var content: () -> Content

    @State private var isVisible = false

    var body: some View {
        VStack(spacing: DesignSystem.Space.s) {
            content()
        }
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 12)
        .onAppear {
            withAnimation(DesignSystem.Motion.present) { isVisible = true }
        }
        .onDisappear { isVisible = false }
    }
}
