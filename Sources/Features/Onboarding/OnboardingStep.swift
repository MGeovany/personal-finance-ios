import Foundation

/// The setup flow, one screen per step.
///
/// Ordered so the numbers build on each other: income, then what is already
/// committed, then what everyday life costs, then debts, then goals. The user
/// sees what is left over grow smaller as they go, which is the point.
enum OnboardingStep: Int, CaseIterable, Identifiable {
    case welcome
    case income
    case fixedExpenses
    case utilities
    case subscriptions
    case lifestyle
    case savings
    case debts
    case goals
    case review

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .welcome: "Cero"
        case .income: "Tus ingresos"
        case .fixedExpenses: "Gastos fijos"
        case .utilities: "Servicios públicos"
        case .subscriptions: "Suscripciones"
        case .lifestyle: "Tu vida diaria"
        case .savings: "Ahorros"
        case .debts: "Tus deudas"
        case .goals: "Otras metas"
        case .review: "Listo"
        }
    }

    var subtitle: String {
        switch self {
        case .welcome:
            "Vamos a ver cuánto debes, cuánto puedes gastar y cuándo podrías quedar libre de deudas."
        case .income:
            "Empezamos por lo que entra cada mes."
        case .fixedExpenses:
            "Lo que pagas siempre: alquiler, colegiatura, seguros."
        case .utilities:
            "Luz, agua, internet, teléfono. Los reservamos aparte de tu presupuesto flexible."
        case .subscriptions:
            "Todo lo que se cobra solo cada mes."
        case .lifestyle:
            "Aproximado, no exacto. Después lo ajustamos con tus gastos reales."
        case .savings:
            "Lo que ya tienes guardado."
        case .debts:
            "Tarjetas, préstamos y cuotas. Con la tasa y el pago mínimo de cada una."
        case .goals:
            "Opcional. Un viaje, un carro, un fondo de emergencia."
        case .review:
            "Con esto ya podemos calcular tus planes."
        }
    }

    /// Steps the user can skip without breaking the plan.
    var isOptional: Bool {
        switch self {
        case .welcome, .income, .review: false
        default: true
        }
    }

    var isFirst: Bool { self == .welcome }
    var isLast: Bool { self == .review }

    var next: OnboardingStep? { OnboardingStep(rawValue: rawValue + 1) }
    var previous: OnboardingStep? { OnboardingStep(rawValue: rawValue - 1) }

    /// Position in the progress indicator, excluding the welcome screen.
    var progressIndex: Int { max(0, rawValue - 1) }
    static var progressCount: Int { allCases.count - 1 }
}
