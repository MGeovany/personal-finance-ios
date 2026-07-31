import Foundation

/// The currencies the app can hold amounts in. Kept as a small closed set so the
/// symbol and formatting rules live in one place; adding a currency is one case.
enum CurrencyCode: String, CaseIterable, Codable, Identifiable, Sendable {
    case hnl = "HNL"
    case usd = "USD"
    case eur = "EUR"
    case mxn = "MXN"
    case gtq = "GTQ"
    case crc = "CRC"
    case cop = "COP"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .hnl: "HNL"
        case .usd: "USD"
        case .eur: "€"
        case .mxn: "MX$"
        case .gtq: "Q"
        case .crc: "₡"
        case .cop: "COL$"
        }
    }

    var displayName: String {
        switch self {
        case .hnl: "Lempira hondureño"
        case .usd: "Dólar estadounidense"
        case .eur: "Euro"
        case .mxn: "Peso mexicano"
        case .gtq: "Quetzal guatemalteco"
        case .crc: "Colón costarricense"
        case .cop: "Peso colombiano"
        }
    }
}
