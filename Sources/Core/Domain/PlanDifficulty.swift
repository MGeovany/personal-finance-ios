import Foundation

/// How demanding a plan will feel day to day. Presented as information, never as
/// a verdict on the user.
enum PlanDifficulty: Int, CaseIterable, Comparable, Sendable {
    case comfortable = 1
    case moderate = 2
    case demanding = 3
    case veryDemanding = 4

    var label: String {
        switch self {
        case .comfortable: "Cómodo"
        case .moderate: "Moderado"
        case .demanding: "Exigente"
        case .veryDemanding: "Muy exigente"
        }
    }

    var detail: String {
        switch self {
        case .comfortable: "Casi no cambia tu forma de vivir."
        case .moderate: "Pide algunos ajustes, nada drástico."
        case .demanding: "Vas a notar el recorte cada semana."
        case .veryDemanding: "Requiere disciplina alta durante varios meses."
        }
    }

    /// Filled dots out of four, for the comparison screen.
    var dots: Int { rawValue }

    static func < (lhs: PlanDifficulty, rhs: PlanDifficulty) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
