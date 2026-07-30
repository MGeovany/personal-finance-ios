import Foundation

/// How a secondary goal competes with debt for the monthly surplus.
enum GoalMode: String, CaseIterable, Codable, Identifiable, Sendable {
    /// Nothing goes in until the debt is gone.
    case paused
    /// A token amount, so the goal still moves.
    case slow
    /// Funded at the rate the plan allows.
    case parallel
    /// Funded first, ahead of extra debt payments.
    case priority

    var id: String { rawValue }

    var label: String {
        switch self {
        case .paused: "Pausada"
        case .slow: "Avanzar lento"
        case .parallel: "En paralelo"
        case .priority: "Prioridad temporal"
        }
    }

    var explanation: String {
        switch self {
        case .paused: "No aporta nada hasta que termines de pagar tus deudas."
        case .slow: "Aporta una cantidad pequeña. Avanza sin retrasar mucho tu fecha."
        case .parallel: "Aporta lo que el plan permita mientras pagas tus deudas."
        case .priority: "Se financia antes del pago extra a la deuda. Retrasa tu fecha."
        }
    }

    /// Fraction of the requested monthly contribution that actually goes in.
    var fundingFactor: Double {
        switch self {
        case .paused: 0
        case .slow: 0.25
        case .parallel: 1.0
        case .priority: 1.0
        }
    }

    /// Priority goals are funded before the debt gets its extra payment.
    var isFundedBeforeDebt: Bool { self == .priority }
}
