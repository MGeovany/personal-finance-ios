import Foundation

/// Formats money the way the app talks about it: whole units, grouped
/// thousands, symbol in front. Cents are dropped on purpose. These numbers are
/// meant to be read at a glance, and a budget of `L2,664.60` reads worse than
/// `L2,665` without being any more useful.
struct MoneyFormatter: MoneyFormatting {
    private let numberFormatter: NumberFormatter

    init(locale: Locale = Locale(identifier: "es")) {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = locale
        formatter.groupingSeparator = ","
        formatter.decimalSeparator = "."
        formatter.usesGroupingSeparator = true
        // Spanish locales leave four-digit numbers ungrouped by default, which
        // would print `L4082` next to `L175,500`. Amounts must look alike.
        formatter.minimumGroupingDigits = 1
        formatter.maximumFractionDigits = 0
        formatter.roundingMode = .halfUp
        self.numberFormatter = formatter
    }

    func string(_ amount: Money, currency: CurrencyCode) -> String {
        let magnitude = numberFormatter.string(from: abs(amount) as NSDecimalNumber) ?? "0"
        let sign = amount < 0 ? "−" : ""
        return "\(sign)\(currency.symbol)\(separator(for: currency))\(magnitude)"
    }

    func compact(_ amount: Money, currency: CurrencyCode) -> String {
        let value = abs(amount).doubleValue
        let sign = amount < 0 ? "−" : ""

        guard value >= 10_000 else { return string(amount, currency: currency) }

        let (scaled, suffix) = value >= 1_000_000 ? (value / 1_000_000, "M") : (value / 1_000, "k")
        let digits = scaled < 100 ? 1 : 0
        let text = String(format: "%.\(digits)f", scaled)
        return "\(sign)\(currency.symbol)\(separator(for: currency))\(text)\(suffix)"
    }

    func signed(_ amount: Money, currency: CurrencyCode) -> String {
        amount > 0 ? "+\(string(amount, currency: currency))" : string(amount, currency: currency)
    }

    /// Single-character symbols sit flush against the number (`L500`), while
    /// letter codes need a space (`USD 500`).
    private func separator(for currency: CurrencyCode) -> String {
        currency.symbol.count > 1 ? " " : ""
    }
}
