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
    private let expenses: ExpenseRepositing
    private let debts: DebtRepositing
    private let subscriptions: SubscriptionRepositing
    private let utilities: UtilityRepositing
    private let goals: GoalRepositing
    private let dateProvider: DateProviding

    private let briefingProvider: PlanBriefingProviding
    private let briefingPresenter: PlanBriefingPresenter
    private let payday: PaydayStatusProviding

    init(
        planStore: PlanStore,
        progress: BudgetProgressCalculating,
        expenses: ExpenseRepositing,
        debts: DebtRepositing,
        subscriptions: SubscriptionRepositing,
        utilities: UtilityRepositing,
        goals: GoalRepositing,
        briefingProvider: PlanBriefingProviding,
        briefingPresenter: PlanBriefingPresenter,
        payday: PaydayStatusProviding,
        dateProvider: DateProviding = SystemDateProvider()
    ) {
        self.payday = payday
        self.planStore = planStore
        self.progress = progress
        self.expenses = expenses
        self.debts = debts
        self.subscriptions = subscriptions
        self.utilities = utilities
        self.goals = goals
        self.briefingProvider = briefingProvider
        self.briefingPresenter = briefingPresenter
        self.dateProvider = dateProvider
    }

    var plan: FinancialPlan { planStore.activePlan }
    var snapshot: FinancialSnapshot { planStore.snapshot }
    var currency: CurrencyCode { planStore.currency }
    private var now: Date { dateProvider.now }

    // MARK: - What the plan allows
    //
    // Read through on every access rather than stored, so an edited budget shows here
    // the moment the user comes back.

    var briefingItems: [BriefingItem] {
        briefingPresenter.items(briefingProvider.briefing)
    }

    // MARK: - Payday

    var paydayStatus: PaydayStatus { payday.status }

    /// Whether the dashboard should lead with the payday card instead of the usual
    /// weekly status.
    var showsPaydayBanner: Bool { paydayStatus.deservesTheTopOfTheScreen }

    /// Hidden while the payday card is still asking for the abonos.
    ///
    /// Showing somebody what they have left to spend, on the day the money is supposed
    /// to leave for their cards, is the app arguing against its own plan. It comes back
    /// as soon as an abono is registered.
    var showsWeeklyStatus: Bool { !showsPaydayBanner }

    /// Everything the plan asks the user to move this payday, each marked done or not.
    var paydayInstructions: [PaydayInstruction] {
        briefingPresenter.instructions(briefingProvider.briefing, progress: paydayStatus.progress)
    }

    var briefingPaymentRows: [(payment: PlanBriefing.DebtPayment, value: String, detail: String)] {
        briefingPresenter.paymentRows(briefingProvider.briefing)
    }

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

    /// One cell in the Mon–Sun strip on the weekly card.
    struct WeekDayProgress: Identifiable, Equatable {
        let id: Int
        let label: String
        let date: Date
        let spent: Money
        let isToday: Bool
        let isFuture: Bool
    }

    /// Always Monday through Sunday of the calendar week, not the plan's month
    /// slice (which can be shorter at the end of a month).
    var weekDays: [WeekDayProgress] {
        let calendar = mondayFirstCalendar
        let range = calendarWeekRange
        let todayStart = calendar.startOfDay(for: now)
        let labels = ["L", "M", "X", "J", "V", "S", "D"]

        return (0..<7).map { index in
            let dayStart = calendar.addingDays(index, to: range.start)
            let spent = expenses.expenses(on: dayStart)
                .filter(\.consumesBudget)
                .reduce(Money.zero) { $0 + $1.amount }
            return WeekDayProgress(
                id: index,
                label: labels[index],
                date: dayStart,
                spent: spent,
                isToday: dayStart == todayStart,
                isFuture: dayStart > todayStart
            )
        }
    }

    /// Delivery orders recorded this calendar month.
    var deliveryOrdersUsed: Int {
        expenses.expenses(inMonthOf: now)
            .filter { $0.consumesBudget && $0.categoryKey == CategoryKeys.delivery }
            .count
    }

    /// Whole orders the plan's delivery budget covers this month.
    var deliveryOrdersAllowed: Int {
        briefingProvider.briefing.delivery.orders
    }

    /// Salidas spent this calendar month.
    var outingsMonthSpent: Money {
        expenses.expenses(inMonthOf: now)
            .filter { $0.consumesBudget && $0.categoryKey == CategoryKeys.outings }
            .reduce(Money.zero) { $0 + $1.amount }
    }

    /// Monthly outings budget from the plan.
    var outingsMonthBudget: Money {
        plan.budget(forCategoryKey: CategoryKeys.outings)
    }

    /// Monday-start calendar for the L–D strip.
    private var mondayFirstCalendar: Calendar {
        var calendar = dateProvider.calendar
        calendar.firstWeekday = 2
        return calendar
    }

    private var calendarWeekRange: (start: Date, end: Date) {
        let calendar = mondayFirstCalendar
        let start = calendar.dateInterval(of: .weekOfYear, for: now)?.start
            ?? calendar.startOfDay(for: now)
        return (start, calendar.addingDays(7, to: start))
    }

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

    func refresh() {
        planStore.refresh()
    }
}
