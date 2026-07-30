import Foundation
import Observation

/// The "¿Qué pasa si...?" screen.
///
/// Everything here is hypothetical by construction: the view model builds
/// mutations and asks the engine, and nothing is written unless the user says so.
@MainActor
@Observable
final class SimulatorViewModel {
    private let planStore: PlanStore
    private let subscriptions: SubscriptionRepositing
    private let debts: DebtRepositing
    private let categories: CategoryRepositing
    private let goals: GoalRepositing
    private let profiles: ProfileProviding

    /// The scenario being explored, chosen from the list.
    var scenario: Scenario = .cancelSubscription
    var amount: Money = 0
    var selectedSubscriptionID: UUID?
    var selectedDebtID: UUID?
    var selectedCategoryKey: String = CategoryKeys.outings
    var selectedGoalID: UUID?
    var selectedMode: GoalMode = .parallel
    var selectedSpeed: PlanSpeed = .balanced
    var selectedStrategy: PayoffStrategy = .avalanche
    var isRecurringIncome = false
    var isCardPurchaseBacked = false

    /// The scenarios the app offers, in the order the spec lists them.
    enum Scenario: String, CaseIterable, Identifiable {
        case cancelSubscription
        case changeCategoryBudget
        case useSavings
        case extraIncome
        case extraPayment
        case newGoal
        case changeGoalPace
        case cardPurchase
        case changePlan
        case changeStrategy

        var id: String { rawValue }

        var label: String {
            switch self {
            case .cancelSubscription: "Cancelar una suscripción"
            case .changeCategoryBudget: "Cambiar un presupuesto"
            case .useSavings: "Usar parte de mis ahorros"
            case .extraIncome: "Recibir un ingreso extra"
            case .extraPayment: "Hacer un pago adicional"
            case .newGoal: "Crear una meta nueva"
            case .changeGoalPace: "Cambiar el ritmo de una meta"
            case .cardPurchase: "Comprar algo con tarjeta"
            case .changePlan: "Cambiar de plan"
            case .changeStrategy: "Cambiar la estrategia"
            }
        }

        var icon: String {
            switch self {
            case .cancelSubscription: "repeat.circle"
            case .changeCategoryBudget: "slider.horizontal.3"
            case .useSavings: "banknote"
            case .extraIncome: "arrow.up.circle"
            case .extraPayment: "arrow.down.circle"
            case .newGoal: "target"
            case .changeGoalPace: "speedometer"
            case .cardPurchase: "creditcard"
            case .changePlan: "square.stack.3d.up"
            case .changeStrategy: "arrow.triangle.branch"
            }
        }

        var needsAmount: Bool {
            switch self {
            case .cancelSubscription, .changeGoalPace, .changePlan, .changeStrategy: false
            default: true
            }
        }
    }

    init(
        planStore: PlanStore,
        subscriptions: SubscriptionRepositing,
        debts: DebtRepositing,
        categories: CategoryRepositing,
        goals: GoalRepositing,
        profiles: ProfileProviding
    ) {
        self.planStore = planStore
        self.subscriptions = subscriptions
        self.debts = debts
        self.categories = categories
        self.goals = goals
        self.profiles = profiles

        self.selectedSubscriptionID = subscriptions.charging().first?.uuid
        self.selectedDebtID = planStore.activePlan.nextTargetDebtID
        self.selectedGoalID = goals.active().first?.uuid
        self.selectedSpeed = planStore.request.speed
        self.selectedStrategy = planStore.request.strategy
    }

    var currency: CurrencyCode { planStore.currency }
    var currentPlan: FinancialPlan { planStore.activePlan }
    var savings: Money { planStore.snapshot.savings }

    var availableSubscriptions: [SubscriptionEntity] { subscriptions.charging() }
    var availableDebts: [DebtEntity] { debts.all().filter { $0.balance > 0 } }
    var availableCards: [DebtEntity] { debts.all().filter { $0.kind.isRevolving && $0.status.allowsNewSpending } }
    var availableCategories: [CategoryEntity] {
        categories.visible().filter { $0.flexibility.participatesInFlexibleBudget }
    }
    var availableGoals: [GoalEntity] { goals.active() }

    /// The result of the current scenario, or nil when it is not complete enough
    /// to mean anything.
    var result: ScenarioResult? {
        guard let mutation else { return nil }
        return planStore.impact(of: mutation)
    }

    /// Translates the screen's state into an engine mutation.
    var mutation: ScenarioMutation? {
        switch scenario {
        case .cancelSubscription:
            guard let id = selectedSubscriptionID else { return nil }
            return .cancelSubscription(id: id)

        case .changeCategoryBudget:
            guard amount > 0 else { return nil }
            return .changeCategoryBudget(key: selectedCategoryKey, to: amount)

        case .useSavings:
            guard amount > 0 else { return nil }
            return .useSavings(amount)

        case .extraIncome:
            guard amount > 0 else { return nil }
            return .extraIncome(amount, recurring: isRecurringIncome)

        case .extraPayment:
            guard amount > 0 else { return nil }
            return .oneTimePayment(amount, debtID: selectedDebtID)

        case .newGoal:
            guard amount > 0 else { return nil }
            // A goal simulated from here is described by its monthly contribution;
            // the target only decides when it ends, not what it costs per month.
            return .addGoal(name: "Meta nueva", monthly: amount, target: amount * 12)

        case .changeGoalPace:
            guard let id = selectedGoalID else { return nil }
            return .changeGoalMode(id: id, mode: selectedMode)

        case .cardPurchase:
            guard amount > 0, let debtID = selectedDebtID ?? availableCards.first?.uuid else { return nil }
            return .cardPurchase(amount, debtID: debtID, backed: isCardPurchaseBacked)

        case .changePlan:
            return .changeSpeed(selectedSpeed)

        case .changeStrategy:
            return .changeStrategy(selectedStrategy)
        }
    }

    /// Turns the simulation into reality. Only the scenarios that map cleanly onto
    /// a stored setting can be applied; the one-off ones stay informational.
    var canApply: Bool {
        switch scenario {
        case .cancelSubscription, .changeCategoryBudget, .changeGoalPace, .changePlan, .changeStrategy: true
        default: false
        }
    }

    func apply() {
        switch scenario {
        case .cancelSubscription:
            guard let id = selectedSubscriptionID,
                  let subscription = availableSubscriptions.first(where: { $0.uuid == id })
            else { return }
            subscription.status = .cancelled
            subscriptions.save()

        case .changeCategoryBudget:
            guard let category = categories.category(forKey: selectedCategoryKey) else { return }
            category.budgetOverride = amount
            categories.save()

        case .changeGoalPace:
            guard let id = selectedGoalID, let goal = goals.goal(withID: id) else { return }
            goal.mode = selectedMode
            goals.save()

        case .changePlan:
            let profile = profiles.profile()
            profile.selectedSpeed = selectedSpeed
            profiles.save()

        case .changeStrategy:
            let profile = profiles.profile()
            profile.strategy = selectedStrategy
            profiles.save()

        default:
            return
        }

        planStore.refresh()
    }
}
