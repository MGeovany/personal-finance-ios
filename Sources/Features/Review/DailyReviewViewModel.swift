import Foundation
import Observation

/// The daily review: what was spent today, what still needs a category, and
/// whether the user has checked their bank apps.
@MainActor
@Observable
final class DailyReviewViewModel {
    private let expenses: ExpenseRepositing
    private let debts: DebtRepositing
    private let subscriptions: SubscriptionRepositing
    private let reviews: ReviewRepositing
    private let progress: BudgetProgressCalculating
    private let planStore: PlanStore
    private let dateProvider: DateProviding

    var hasCheckedExternalApps = false

    init(
        expenses: ExpenseRepositing,
        debts: DebtRepositing,
        subscriptions: SubscriptionRepositing,
        reviews: ReviewRepositing,
        progress: BudgetProgressCalculating,
        planStore: PlanStore,
        dateProvider: DateProviding = SystemDateProvider()
    ) {
        self.expenses = expenses
        self.debts = debts
        self.subscriptions = subscriptions
        self.reviews = reviews
        self.progress = progress
        self.planStore = planStore
        self.dateProvider = dateProvider
    }

    var currency: CurrencyCode { planStore.currency }
    private var now: Date { dateProvider.now }

    var todaysExpenses: [ExpenseEntity] { expenses.expenses(on: now) }
    var spentToday: Money { progress.spentToday(on: now) }
    var weekRemaining: Money { progress.weekTotal(plan: planStore.activePlan, on: now).remaining }
    var uncategorized: [ExpenseEntity] { expenses.needingReview() }

    /// Cards used today, so the user can cross-check against their statements.
    var cardsUsedToday: [DebtEntity] {
        let ids = Set(todaysExpenses.compactMap(\.debtID))
        return ids.compactMap { debts.debt(withID: $0) }
    }

    /// Card purchases with no money set aside: the thing most worth catching daily.
    var unbackedToday: Money {
        todaysExpenses
            .filter { $0.backing == .financed }
            .reduce(Money.zero) { $0 + $1.amount }
    }

    /// Charges the app expects around today, as a prompt for what might be missing.
    var expectedCharges: [SubscriptionEntity] {
        let today = dateProvider.calendar.component(.day, from: now)
        return subscriptions.charging().filter { subscription in
            guard let day = subscription.chargeDay else { return false }
            return abs(day - today) <= 1
        }
    }

    var isComplete: Bool { reviews.isComplete(.daily, on: now) }

    func categorize(_ expense: ExpenseEntity, as key: String) {
        expense.categoryKey = key
        expense.needsReview = false
        expenses.save()
        planStore.refresh()
    }

    func delete(_ expense: ExpenseEntity) {
        expenses.delete(expense)
        planStore.refresh()
    }

    func complete() {
        reviews.complete(
            .daily,
            on: now,
            checkedExternalApps: hasCheckedExternalApps,
            surplusDestination: nil,
            surplusAmount: 0
        )
    }
}
