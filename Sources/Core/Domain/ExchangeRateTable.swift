import Foundation

/// A set of exchange rates, and the honest story of where they came from.
///
/// The date and the origin travel with the numbers because a converted amount is
/// only as trustworthy as the rate behind it. An app that quietly used a rate from
/// six months ago would be doing arithmetic on a number nobody can check.
struct ExchangeRateTable: Equatable, Codable, Sendable {
    /// Units of each currency per one US dollar. The dollar is the pivot because it
    /// is the currency prices actually arrive in.
    var perUSD: [CurrencyCode: Double]
    var fetchedAt: Date
    var origin: Origin

    enum Origin: String, Codable, Sendable {
        /// Shipped with the app. Right when it was written, drifting ever since.
        case bundled
        /// Fetched from the rate service.
        case network
    }

    func rate(for currency: CurrencyCode) -> Double? {
        perUSD[currency]
    }

    /// Rates move daily, so anything older than a day is worth saying out loud.
    func isStale(now: Date, tolerance: TimeInterval = 60 * 60 * 24) -> Bool {
        now.timeIntervalSince(fetchedAt) > tolerance
    }

    /// The rates the app ships with, so the very first launch can convert before it
    /// has ever reached the network.
    ///
    /// Approximate on purpose: they exist to keep a plan plausible, not to be exact.
    /// `fetchedAt` is the day they were written down rather than `Date()`, which
    /// would claim they are current every time the app starts.
    static let bundled = ExchangeRateTable(
        perUSD: [
            .usd: 1,
            .hnl: 26.0,
            .eur: 0.92,
            .mxn: 18.5,
            .gtq: 7.8,
            .crc: 520.0,
            .cop: 4_000.0,
        ],
        fetchedAt: Calendar(identifier: .gregorian)
            .date(from: DateComponents(year: 2026, month: 7, day: 30)) ?? Date(timeIntervalSince1970: 0),
        origin: .bundled
    )
}
