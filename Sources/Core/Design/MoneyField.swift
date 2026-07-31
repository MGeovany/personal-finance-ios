import SwiftUI

/// An amount input.
///
/// Typing money should never fight the user: the field holds text, accepts the
/// separators people actually type, and only converts on the way out.
///
/// Every amount in the app can also be typed in a second currency. A card statement
/// arrives in dollars while the salary that pays it arrives in lempiras, and asking
/// the user to do that arithmetic in their head is how wrong numbers get saved. The
/// switch changes only the currency being *typed*: the bound value stays in the
/// plan's currency, converted as it is entered, so nothing downstream has to know
/// this happened.
struct MoneyField: View {
    let title: String
    @Binding var amount: Money
    /// The currency `amount` is stored in.
    var currency: CurrencyCode = .hnl
    var placeholder: String = "0"
    /// Off for the rare field where a second currency would only add noise.
    var allowsCurrencySwitch: Bool = true
    /// Optional guidance under the field. How to arrive at the number, not what
    /// the number means once saved.
    var caption: String? = nil

    @Environment(\.exchangeRates) private var rates
    @Environment(\.moneyFormatter) private var money

    /// The currency the user is typing in, which starts as the stored one.
    @State private var entry: CurrencyCode?
    @State private var text: String = ""
    @FocusState private var isFocused: Bool

    private var typing: CurrencyCode { entry ?? currency }

    /// The pair offered by the switch: the stored currency and the dollar, since
    /// that is the one prices actually arrive in. A plan already in dollars gets
    /// the lempira instead.
    private var options: [CurrencyCode] {
        currency == .usd ? [.usd, .hnl] : [currency, .usd]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Space.s) {
            HStack(alignment: .firstTextBaseline) {
                Text(title).fieldLabel()

                Spacer(minLength: Layout.gap)

                if allowsCurrencySwitch, options.count > 1 {
                    CurrencySwitch(options: options, selection: currencyBinding)
                }
            }

            field

            if let caption {
                Text(caption)
                    .font(Typography.caption)
                    .foregroundStyle(Palette.tertiaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let equivalent {
                Text(equivalent)
                    .font(Typography.caption)
                    .foregroundStyle(Palette.tertiaryText)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(DesignSystem.Motion.swap, value: typing)
        .onAppear { showAmount() }
        .onChange(of: amount) { _, updated in
            // A draft can be filled in after the field is on screen, or reset after
            // a save. Typing is left alone: only a change from somewhere else is
            // written back into the field.
            guard converted(MoneyParser.parse(text) ?? 0, from: typing, to: currency) != updated else { return }
            showAmount()
        }
    }

    /// Shows an empty field rather than a literal zero, which users would then have
    /// to delete before typing.
    private func showAmount() {
        text = amount > 0 ? MoneyParser.editableText(converted(amount, to: typing)) : ""
    }

    private var field: some View {
        HStack(spacing: DesignSystem.Space.s) {
            Text(typing.symbol)
                .font(Typography.amount)
                .foregroundStyle(Palette.tertiaryText)
                .contentTransition(.numericText())
                .id(typing)

            TextField(placeholder, text: $text)
                .font(Typography.statistic)
                .foregroundStyle(Palette.primaryText)
                .keyboardType(.decimalPad)
                .focused($isFocused)
                .onChange(of: text) { _, newValue in
                    let masked = MoneyParser.masked(newValue)
                    if masked != newValue { text = masked }
                    let typed = MoneyParser.parse(masked) ?? 0
                    // Money fields are magnitudes: a negative amount is never a valid entry.
                    amount = max(0, converted(typed, from: typing, to: currency))
                }
        }
        .fieldWell(isFocused: isFocused, height: 60)
    }

    /// What will actually be saved, shown only while the user is typing in a
    /// currency the plan does not use.
    private var equivalent: String? {
        guard typing != currency, amount > 0 else { return nil }
        return "Se guarda como \(money.string(amount, currency: currency))"
    }

    /// Switching currencies keeps the amount of money the same and restates it, so
    /// the field never silently changes what the user meant.
    private var currencyBinding: Binding<CurrencyCode> {
        Binding(
            get: { typing },
            set: { next in
                guard next != typing else { return }
                entry = next
                text = amount > 0 ? MoneyParser.editableText(converted(amount, to: next)) : ""
            }
        )
    }

    private func converted(_ value: Money, to target: CurrencyCode) -> Money {
        converted(value, from: currency, to: target)
    }

    private func converted(_ value: Money, from source: CurrencyCode, to target: CurrencyCode) -> Money {
        guard source != target else { return value }
        return rates.convert(value, from: source, to: target)
    }
}

/// The two-position currency switch.
///
/// Small, and animated, because it needs to be discoverable without ever looking
/// like the main event next to the amount itself.
struct CurrencySwitch: View {
    let options: [CurrencyCode]
    @Binding var selection: CurrencyCode

    @Namespace private var indicator

    var body: some View {
        HStack(spacing: 2) {
            ForEach(options) { option in
                let isSelected = option == selection

                Button {
                    withAnimation(DesignSystem.Motion.swap) { selection = option }
                } label: {
                    Text(option.switchLabel)
                        .font(Typography.text(11, .semibold))
                        .foregroundStyle(isSelected ? Palette.invertedText : Palette.tertiaryText)
                        .padding(.horizontal, DesignSystem.Space.s)
                        // A one-glyph symbol and a three-letter code have to yield
                        // the same pill, or the indicator changes shape as it slides.
                        .frame(minWidth: 34, minHeight: 26)
                        .background {
                            if isSelected {
                                Capsule()
                                    .fill(Palette.accent)
                                    .matchedGeometryEffect(id: "currency", in: indicator)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Escribir en \(option.displayName)")
                .accessibilityAddTraits(isSelected ? [.isSelected] : [])
            }
        }
        .padding(2)
        .background(Palette.surfaceSunken.opacity(0.9), in: Capsule())
        .overlay {
            Capsule().strokeBorder(Color.white.opacity(0.5), lineWidth: 1)
        }
        .sensoryFeedback(.selection, trigger: selection)
    }
}

private extension CurrencyCode {
    /// Always the ISO code in the switch (HNL / USD), so lempiras are never
    /// confused with a lone "L".
    var switchLabel: String { rawValue }
}

/// Reads and writes the plain text form of an amount.
enum MoneyParser {
    /// Commas are always thousands separators; only a dot starts the cents.
    ///
    /// Treating a trailing comma as a decimal made `1,200` become `1.20` when the
    /// user deleted a zero. The field regroups instead, so that edit becomes `120`.
    static func parse(_ text: String) -> Money? {
        // Signs are stripped: these fields only accept amounts at or above zero.
        let digitsAndSeparators = text.filter { $0.isNumber || $0 == "." || $0 == "," }
        guard !digitsAndSeparators.isEmpty else { return nil }

        let whole: String
        let fraction: String

        if let dot = digitsAndSeparators.firstIndex(of: ".") {
            whole = String(digitsAndSeparators[..<dot]).filter(\.isNumber)
            fraction = String(
                String(digitsAndSeparators[digitsAndSeparators.index(after: dot)...])
                    .filter(\.isNumber)
                    .prefix(2)
            )
        } else {
            whole = digitsAndSeparators.filter(\.isNumber)
            fraction = ""
        }

        let normalized = whole + (fraction.isEmpty ? "" : "." + fraction)
        guard !normalized.isEmpty, normalized != "." else { return nil }
        guard let value = Money(string: normalized), value >= 0 else { return nil }
        return value
    }

    /// Live mask for the field: `1000` becomes `1,000` as the user types.
    ///
    /// Grouping uses commas; cents use a dot. Commas in the raw input are stripped
    /// and re-applied, so deleting a digit from `1,200` yields `120`, never `1.20`.
    static func masked(_ text: String) -> String {
        let work = text.filter { $0.isNumber || $0 == "." || $0 == "," }
        guard !work.isEmpty else { return "" }

        let parts = work.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
        let grouped = groupThousands(String(parts[0]).filter(\.isNumber))
        guard parts.count > 1 else { return grouped }

        let fraction = String(String(parts[1]).filter(\.isNumber).prefix(2))
        return grouped + "." + fraction
    }

    /// Grouped text for putting an existing amount back into the field.
    ///
    /// Cents are kept: a lempira amount restated in dollars is rarely whole, and
    /// rounding it to the unit would quietly change what gets saved.
    static func editableText(_ amount: Money) -> String {
        var result = Money()
        var value = amount
        NSDecimalRound(&result, &value, 2, .plain)
        return masked(NSDecimalNumber(decimal: result).stringValue)
    }

    /// Inserts a comma every three digits from the right (`1000` → `1,000`).
    private static func groupThousands(_ digits: String) -> String {
        guard !digits.isEmpty else { return "" }

        let trimmed = digits.drop { $0 == "0" }
        let core = trimmed.isEmpty ? "0" : String(trimmed)

        var grouped = ""
        for (index, character) in core.reversed().enumerated() {
            if index > 0, index.isMultiple(of: 3) { grouped.append(",") }
            grouped.append(character)
        }
        return String(grouped.reversed())
    }
}
