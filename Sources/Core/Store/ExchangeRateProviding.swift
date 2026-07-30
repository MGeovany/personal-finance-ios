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

/// Built-in approximate rates, used so a card in dollars can sit next to a salary
/// in lempiras without blocking the user on a network call.
struct StaticExchangeRateProvider: ExchangeRateProviding {
    /// Units of each currency per one US dollar.
    private let perUSD: [CurrencyCode: Double] = [
        .usd: 1,
        .hnl: 26.0,
        .eur: 0.92,
        .mxn: 18.5,
        .gtq: 7.8,
        .crc: 520.0,
        .cop: 4_000.0,
    ]

    func convert(_ amount: Money, from source: CurrencyCode, to target: CurrencyCode) -> Money {
        guard source != target else { return amount }
        guard let sourceRate = perUSD[source], let targetRate = perUSD[target], sourceRate > 0 else {
            return amount
        }
        return amount.scaled(by: targetRate / sourceRate)
    }
}
