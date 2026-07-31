import Foundation

/// Converts amounts between currencies.
///
/// The app supports several currencies, but a plan only makes sense in one, so
/// every amount is converted to the user's main currency before the engine sees
/// it. Behind a protocol so live rates can replace the built-in table later
/// without touching the assembler.
protocol ExchangeRateProviding: Sendable {
    func convert(_ amount: Money, from source: CurrencyCode, to target: CurrencyCode) -> Money
}

/// Converts with a table that never changes.
///
/// Used where the network has no business being involved: previews, and anywhere a
/// fixed rate makes a result reproducible. The app itself uses
/// `LiveExchangeRateProvider`, which starts from this same bundled table and replaces
/// it as soon as it can reach the rate service.
struct StaticExchangeRateProvider: ExchangeRateProviding {
    let table: ExchangeRateTable

    init(table: ExchangeRateTable = .bundled) {
        self.table = table
    }

    func convert(_ amount: Money, from source: CurrencyCode, to target: CurrencyCode) -> Money {
        guard source != target else { return amount }
        guard let sourceRate = table.rate(for: source),
              let targetRate = table.rate(for: target),
              sourceRate > 0
        else { return amount }

        return amount.scaled(by: targetRate / sourceRate)
    }
}
