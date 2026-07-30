import Foundation

/// Renders amounts. Behind a protocol because almost every view needs it, and a
/// view that takes a formatter is a view that can be previewed and tested.
protocol MoneyFormatting: Sendable {
    /// Full amount with its currency symbol: `L24,000`.
    func string(_ amount: Money, currency: CurrencyCode) -> String
    /// Shortened for tight spaces: `L24.0k`.
    func compact(_ amount: Money, currency: CurrencyCode) -> String
    /// Signed, for differences: `+L500` / `−L500`.
    func signed(_ amount: Money, currency: CurrencyCode) -> String
}
