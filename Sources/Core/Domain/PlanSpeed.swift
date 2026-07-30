import Foundation

/// How fast the user wants to attack their debt. The three speeds are the same
/// algorithm with different parameters — see `PlanTuning`.
enum PlanSpeed: String, CaseIterable, Codable, Identifiable, Sendable {
    case loose
    case balanced
    case aggressive

    var id: String { rawValue }

    /// The name shipped by default. Users can rename any plan, so the UI must
    /// read the stored name rather than this one.
    var defaultName: String {
        switch self {
        case .loose: "Suelto"
        case .balanced: "Balanceado"
        case .aggressive: "Agresivo"
        }
    }

    var shortDescription: String {
        switch self {
        case .loose: "Prioriza tu comodidad diaria"
        case .balanced: "Equilibra rapidez y calidad de vida"
        case .aggressive: "Prioriza salir de deudas cuanto antes"
        }
    }

    /// Balanced is the recommendation the app presents by default.
    static var recommended: PlanSpeed { .balanced }

    /// Comparison screens read left to right from most comfortable to fastest.
    static var displayOrder: [PlanSpeed] { [.loose, .balanced, .aggressive] }
}
