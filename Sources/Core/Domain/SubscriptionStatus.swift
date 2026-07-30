import Foundation

/// Whether a subscription is still costing money.
enum SubscriptionStatus: String, CaseIterable, Codable, Identifiable, Sendable {
    case active
    case paused
    case cancelled

    var id: String { rawValue }

    var label: String {
        switch self {
        case .active: "Activa"
        case .paused: "Pausada"
        case .cancelled: "Cancelada"
        }
    }
}
