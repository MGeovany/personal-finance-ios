import Foundation

/// Where leftover money goes — from a cheaper-than-expected utility bill, or from
/// a week that closed under budget.
enum SurplusDestination: String, CaseIterable, Codable, Identifiable, Sendable {
    case debt
    case emergencyFund
    case goal
    case carryOver

    var id: String { rawValue }

    var label: String {
        switch self {
        case .debt: "Abonar a una deuda"
        case .emergencyFund: "Guardar como emergencia"
        case .goal: "Enviar a una meta"
        case .carryOver: "Pasar a la semana siguiente"
        }
    }

    var icon: String {
        switch self {
        case .debt: "arrow.down.circle"
        case .emergencyFund: "shield"
        case .goal: "target"
        case .carryOver: "arrow.right.circle"
        }
    }

    /// While expensive debt exists, paying it down beats every other use.
    static func recommended(hasHighInterestDebt: Bool) -> SurplusDestination {
        hasHighInterestDebt ? .debt : .emergencyFund
    }
}
