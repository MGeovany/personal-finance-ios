import Foundation

/// Where a debt stands in the user's plan. The status drives whether the debt
/// still receives payments and whether it can be spent on.
enum DebtStatus: String, CaseIterable, Codable, Identifiable, Sendable {
    case active
    case paying
    case doNotUse
    case payAndClose
    case pendingClosure
    case paid
    case closed

    var id: String { rawValue }

    var label: String {
        switch self {
        case .active: "Activa"
        case .paying: "En pago"
        case .doNotUse: "No utilizar"
        case .payAndClose: "Pagar y cancelar"
        case .pendingClosure: "Pendiente de cancelación"
        case .paid: "Pagada"
        case .closed: "Cancelada"
        }
    }

    /// Settled debts leave the projection entirely.
    var isSettled: Bool {
        self == .paid || self == .closed
    }

    /// A debt still being paid down counts toward the payoff projection.
    var participatesInProjection: Bool { !isSettled }

    /// Whether new spending on this account is allowed.
    var allowsNewSpending: Bool {
        self == .active || self == .paying
    }
}
