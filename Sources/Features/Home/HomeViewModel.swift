import Foundation
import Observation

/// Everything the main screen shows, derived in one place.
///
/// The dashboard has to answer five questions at a glance, so the view stays a
/// layout and every number it prints is computed here.
@MainActor
@Observable
final class HomeViewModel {
    private let planStore: PlanStore
    private let progress: BudgetProgressCalculating
    private let debts: DebtRepositing
    private let subscriptions: SubscriptionRepositing
    private let utilities: UtilityRepositing
    private let goals: GoalRepositing
    private let reviews: ReviewRepositing
    private let dateProvider: DateProviding

    init(
        planStore: PlanStore,
        progress: BudgetProgressCalculating,
        debts: DebtRepositing,
        subscriptions: SubscriptionRepositing,
        utilities: UtilityRepositing,
        goals: GoalRepositing,
        reviews: ReviewRepositing,
        dateProvider: DateProviding = SystemDateProvider()
    ) {
        self.planStore = planStore
        self.progress = progress
        self.debts = debts
        self.subscriptions = subscriptions
        self.utilities = utilities
        self.goals = goals
        self.reviews = reviews
        self.dateProvider = dateProvider
    }

    var plan: FinancialPlan { planStore.activePlan }
    var snapshot: FinancialSnapshot { planStore.snapshot }
    var currency: CurrencyCode { planStore.currency }
    private var now: Date { dateProvider.now }

    // MARK: - 1. How much do I owe?

    var totalDebt: Money { snapshot.totalDebt }

    /// Change since last month, measured from payments recorded this month against
    /// interest that accrued. Positive means the debt went down.
    var debtChangeThisMonth: Money {
        let calendar = dateProvider.calendar
        let monthStart = calendar.startOfMonth(for: now)

        let paid = debts.all()
            .flatMap(\.payments)
            .filter { $0.date >= monthStart }
            .reduce(Money.zero) { $0 + $1.amount }

        let interest = snapshot.activeDebts.reduce(Money.zero) { $0 + $1.monthlyInterestCost }
        return paid - interest
    }

    // MARK: - 2. How much can I spend?

    var weekBudget: BudgetConsumption { progress.weekTotal(plan: plan, on: now) }
    var monthBudget: BudgetConsumption { progress.monthTotal(plan: plan, on: now) }
    var spentToday: Money { progress.spentToday(on: now) }

    // MARK: - 3. What should I pay now?

    /// The debt the extra payment goes to under the active strategy.
    var targetDebt: DebtEntity? {
        plan.nextTargetDebtID.flatMap { debts.debt(withID: $0) }
    }

    var recommendedPayment: Money { plan.monthlyDebtPayment }
    var extraPayment: Money { plan.allocation.extraDebtPayment }

    /// Debts whose due date is within the next week, so nothing is missed.
    var upcomingDueDebts: [DebtEntity] {
        let calendar = dateProvider.calendar
        let today = calendar.component(.day, from: now)

        return debts.all()
            .filter { $0.status.participatesInProjection && $0.balance > 0 }
            .filter { debt in
                guard let dueDay = debt.dueDay else { return false }
                let distance = dueDay - today
                return distance >= 0 && distance <= 7
            }
            .sorted { ($0.dueDay ?? 0) < ($1.dueDay ?? 0) }
    }

    // MARK: - 4. When will I be debt free?

    var freedomDate: Date? { plan.freedomDate }
    var monthsToFreedom: Int? { plan.monthsToFreedom }

    // MARK: - 5. What is slowing me down?

    var warnings: [PlanWarning] { plan.warnings }

    /// Goals delaying the plan, worst first.
    var delayingGoals: [GoalImpact] {
        plan.delayedGoals.sorted { $0.daysDelayed > $1.daysDelayed }
    }

    // MARK: - Supporting sections

    var reservedUtilities: Money {
        utilities.active().reduce(Money.zero) { $0 + $1.monthlyReserve }
    }

    /// Subscriptions charging in the next seven days.
    var upcomingSubscriptions: [SubscriptionEntity] {
        let today = dateProvider.calendar.component(.day, from: now)
        return subscriptions.charging()
            .filter { subscription in
                guard let day = subscription.chargeDay else { return false }
                let distance = day - today
                return distance >= 0 && distance <= 7
            }
            .sorted { ($0.chargeDay ?? 0) < ($1.chargeDay ?? 0) }
    }

    var activeGoals: [GoalEntity] { goals.active() }

    func funding(for goal: GoalEntity) -> Money {
        plan.allocation.funding(for: goal.uuid)
    }

    var needsDailyReview: Bool {
        !reviews.isComplete(.daily, on: now)
    }

    var isMonthClosePending: Bool {
        let calendar = dateProvider.calendar
        let isLastDays = calendar.daysRemainingInMonth(from: now) <= 2
        return isLastDays && !reviews.isComplete(.monthly, on: now)
    }

    func refresh() {
        planStore.refresh()
    }
}
