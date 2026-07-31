import Foundation

/// Remembers the last rates the app managed to fetch.
///
/// Small and self-contained, so it lives in `UserDefaults` rather than in the
/// SwiftData store: it is not the user's data, it is a cache the app can rebuild.
protocol ExchangeRateStoring: Sendable {
    func load() -> ExchangeRateTable?
    func save(_ table: ExchangeRateTable)
}

struct UserDefaultsExchangeRateStore: ExchangeRateStoring {
    private let key = "cero.exchangeRates"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> ExchangeRateTable? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(ExchangeRateTable.self, from: data)
    }

    func save(_ table: ExchangeRateTable) {
        guard let data = try? JSONEncoder().encode(table) else { return }
        defaults.set(data, forKey: key)
    }
}

/// Used by previews and by anything that must not touch real storage.
struct EphemeralExchangeRateStore: ExchangeRateStoring {
    func load() -> ExchangeRateTable? { nil }
    func save(_ table: ExchangeRateTable) {}
}
