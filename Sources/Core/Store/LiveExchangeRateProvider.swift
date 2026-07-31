import Foundation

/// Converts with the best rates the app currently has, and goes looking for better
/// ones in the background.
///
/// Conversion stays synchronous on purpose. It happens deep inside building a
/// snapshot, once per amount, and no screen should wait on the network to show a
/// balance. So the rates are held in memory and `refresh()` swaps them in when a
/// fetch succeeds.
///
/// The order of preference on launch is the last successful fetch, then the table
/// shipped with the app. Offline means the previous rates keep working rather than
/// conversions silently becoming wrong.
final class LiveExchangeRateProvider: ExchangeRateProviding {
    private let fetcher: ExchangeRateFetching
    private let store: ExchangeRateStoring
    /// Rates are read from every thread that builds a snapshot and written by the
    /// refresh task, so the table is guarded rather than assumed to be main-actor.
    private let lock = NSLock()
    private var table: ExchangeRateTable

    init(
        fetcher: ExchangeRateFetching = OpenExchangeRateFetcher(),
        store: ExchangeRateStoring = UserDefaultsExchangeRateStore()
    ) {
        self.fetcher = fetcher
        self.store = store
        self.table = store.load() ?? .bundled
    }

    // MARK: - Converting

    func convert(_ amount: Money, from source: CurrencyCode, to target: CurrencyCode) -> Money {
        guard source != target else { return amount }

        let current = currentTable
        guard let sourceRate = current.rate(for: source),
              let targetRate = current.rate(for: target),
              sourceRate > 0
        else {
            // A currency the table does not carry is left alone rather than converted
            // by a number that does not exist.
            return amount
        }

        return amount.scaled(by: targetRate / sourceRate)
    }

    /// What the app is converting with right now, for anywhere that needs to say so.
    var currentTable: ExchangeRateTable {
        lock.lock()
        defer { lock.unlock() }
        return table
    }

    // MARK: - Refreshing

    /// Fetches new rates, unless the ones in hand are recent enough to be worth
    /// keeping. Failure is not an error the user needs to hear about: the previous
    /// rates are still there and still the best answer available.
    ///
    /// - Parameter minimumAge: how old the current rates must be before the network is
    ///   worth bothering. Rates are published once a day.
    @discardableResult
    func refresh(minimumAge: TimeInterval = 60 * 60 * 6, now: Date = Date()) async -> Bool {
        guard currentTable.isStale(now: now, tolerance: minimumAge) else { return false }

        do {
            let fetched = try await fetcher.fetch()
            apply(fetched)
            return true
        } catch {
            #if DEBUG
            print("[Cero] Exchange rates unchanged, keeping \(currentTable.origin.rawValue) rates from \(currentTable.fetchedAt): \(error)")
            #endif
            return false
        }
    }

    private func apply(_ fetched: ExchangeRateTable) {
        lock.lock()
        table = fetched
        lock.unlock()
        store.save(fetched)
    }
}
