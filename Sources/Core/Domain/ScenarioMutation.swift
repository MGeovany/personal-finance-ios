import Foundation

/// A hypothetical decision. Applying one produces a new snapshot; nothing is
/// written until the user confirms, which is what makes the simulator safe.
enum ScenarioMutation: Equatable, Identifiable, Sendable {
    case cancelSubscription(id: UUID)
    case changeCategoryBudget(key: String, to: Money)
    case useSavings(Money)
    case extraIncome(Money, recurring: Bool)
    case oneTimePayment(Money, debtID: UUID?)
    case addGoal(name: String, monthly: Money, target: Money)
    case changeGoalMode(id: UUID, mode: GoalMode)
    case cardPurchase(Money, debtID: UUID, backed: Bool)
    case changeStrategy(PayoffStrategy)
    case changeSpeed(PlanSpeed)

    var id: String {
        switch self {
        case .cancelSubscription(let id): "cancel-sub-\(id)"
        case .changeCategoryBudget(let key, _): "category-\(key)"
        case .useSavings: "use-savings"
        case .extraIncome: "extra-income"
        case .oneTimePayment: "one-time-payment"
        case .addGoal(let name, _, _): "add-goal-\(name)"
        case .changeGoalMode(let id, _): "goal-mode-\(id)"
        case .cardPurchase: "card-purchase"
        case .changeStrategy(let strategy): "strategy-\(strategy.rawValue)"
        case .changeSpeed(let speed): "speed-\(speed.rawValue)"
        }
    }

    var title: String {
        switch self {
        case .cancelSubscription: "Cancelar una suscripción"
        case .changeCategoryBudget: "Cambiar un presupuesto"
        case .useSavings: "Usar parte de tus ahorros"
        case .extraIncome: "Recibir un ingreso extra"
        case .oneTimePayment: "Hacer un pago adicional"
        case .addGoal: "Crear una meta nueva"
        case .changeGoalMode: "Cambiar el ritmo de una meta"
        case .cardPurchase: "Comprar algo con tarjeta"
        case .changeStrategy: "Cambiar la estrategia de pago"
        case .changeSpeed: "Cambiar de plan"
        }
    }
}
