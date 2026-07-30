import Foundation

/// The order in which extra money attacks debts.
enum PayoffStrategy: String, CaseIterable, Codable, Identifiable, Sendable {
    /// Highest interest rate first. Mathematically cheapest, so it is the default.
    case avalanche
    /// Smallest balance first. Slower but gives quicker visible wins.
    case snowball
    /// The user pins the order for personal reasons.
    case custom

    var id: String { rawValue }

    var label: String {
        switch self {
        case .avalanche: "Avalancha"
        case .snowball: "Bola de nieve"
        case .custom: "Personalizada"
        }
    }

    var explanation: String {
        switch self {
        case .avalanche:
            "Ataca primero la deuda con mayor tasa de interés. Es la que menos intereses te cuesta en total."
        case .snowball:
            "Ataca primero la deuda con menor saldo. Tardas un poco más, pero ves deudas desaparecer antes."
        case .custom:
            "Tú decides el orden. Útil cuando una deuda importa por razones personales."
        }
    }

    static var recommended: PayoffStrategy { .avalanche }
}
