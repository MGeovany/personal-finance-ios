import Foundation

/// Asks the network for today's rates.
protocol ExchangeRateFetching: Sendable {
    /// Throws when the network is unreachable or the answer cannot be trusted, which
    /// is what tells the provider to keep using the rates it already has.
    func fetch() async throws -> ExchangeRateTable
}

/// Never reaches the network, so previews and reproducible runs keep the rates they
/// started with.
struct OfflineExchangeRateFetcher: ExchangeRateFetching {
    struct Unavailable: Error {}

    func fetch() async throws -> ExchangeRateTable {
        throw Unavailable()
    }
}

/// Reads rates from the open exchange rate service.
///
/// Chosen because it needs no API key and it publishes the lempira, which the rate
/// feeds built on European Central Bank data do not. One request returns every
/// currency the app supports, so there is nothing to loop over.
struct OpenExchangeRateFetcher: ExchangeRateFetching {
    enum Failure: Error {
        case badResponse
        case serviceReportedFailure
        /// The answer arrived but did not contain the currencies the app needs, which
        /// makes it worse than the rates already cached.
        case missingCurrencies
    }

    private let endpoint = URL(string: "https://open.er-api.com/v6/latest/USD")!
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetch() async throws -> ExchangeRateTable {
        var request = URLRequest(url: endpoint)
        // Short, because a plan should never wait on a currency conversion. Failing
        // fast means falling back to the cached rates, which is the correct outcome.
        request.timeoutInterval = 10
        request.cachePolicy = .reloadIgnoringLocalCacheData

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw Failure.badResponse
        }

        let payload = try JSONDecoder().decode(Payload.self, from: data)
        guard payload.result == "success" else { throw Failure.serviceReportedFailure }

        let rates = payload.supportedRates
        // The dollar is the pivot every conversion goes through, and the user's own
        // currency has to be there for the table to be worth caching.
        guard rates[.usd] != nil, rates.count > 1 else { throw Failure.missingCurrencies }

        return ExchangeRateTable(
            perUSD: rates,
            fetchedAt: payload.updatedAt ?? Date(),
            origin: .network
        )
    }

    /// Only the fields the app reads. The service sends many more currencies than
    /// `CurrencyCode` knows about, and the extras are dropped rather than stored.
    private struct Payload: Decodable {
        let result: String
        let timeLastUpdateUnix: TimeInterval?
        let rates: [String: Double]

        enum CodingKeys: String, CodingKey {
            case result
            case timeLastUpdateUnix = "time_last_update_unix"
            case rates
        }

        var updatedAt: Date? {
            timeLastUpdateUnix.map(Date.init(timeIntervalSince1970:))
        }

        var supportedRates: [CurrencyCode: Double] {
            rates.reduce(into: [CurrencyCode: Double]()) { result, entry in
                guard let code = CurrencyCode(rawValue: entry.key), entry.value > 0 else { return }
                result[code] = entry.value
            }
        }
    }
}
