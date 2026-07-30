import SwiftUI

/// An amount input.
///
/// Typing money should never fight the user: the field holds text, accepts the
/// separators people actually type, and only converts on the way out.
struct MoneyField: View {
    let title: String
    @Binding var amount: Money
    var currency: CurrencyCode = .hnl
    var placeholder: String = "0"

    @State private var text: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.tightGap) {
            Text(title)
                .font(Typography.label)
                .foregroundStyle(Palette.secondaryText)

            HStack(spacing: Layout.tightGap) {
                Text(currency.symbol)
                    .font(Typography.amount)
                    .foregroundStyle(Palette.tertiaryText)

                TextField(placeholder, text: $text)
                    .font(Typography.statistic)
                    .keyboardType(.decimalPad)
                    .focused($isFocused)
                    .onChange(of: text) { _, newValue in
                        amount = MoneyParser.parse(newValue) ?? 0
                    }
            }
            .padding(.horizontal, Layout.gap)
            .padding(.vertical, 10)
            .background(Palette.surfaceMuted, in: RoundedRectangle(cornerRadius: Layout.chipRadius, style: .continuous))
        }
        .onAppear {
            // Show an empty field rather than a literal zero, which users then
            // have to delete before typing.
            text = amount > 0 ? MoneyParser.editableText(amount) : ""
        }
    }
}

/// Reads and writes the plain text form of an amount.
enum MoneyParser {
    static func parse(_ text: String) -> Money? {
        let cleaned = text
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: " ", with: "")
            .trimmingCharacters(in: .whitespaces)
        guard !cleaned.isEmpty else { return nil }
        return Money(string: cleaned)
    }

    /// Unformatted, so the value can go straight back into a text field.
    static func editableText(_ amount: Money) -> String {
        NSDecimalNumber(decimal: amount.rounded).stringValue
    }
}
