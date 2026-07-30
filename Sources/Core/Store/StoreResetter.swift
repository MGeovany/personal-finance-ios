import Foundation
import SwiftData

/// Empties the store and leaves the app as if it had just been installed.
@MainActor
protocol StoreResetting {
    /// Deletes everything the user has entered, then restores the default
    /// categories so the next setup has something to budget against.
    func reset()
}

@MainActor
struct StoreResetter: StoreResetting {
    private let context: ModelContext
    private let categories: CategoryRepositing
    private let planStore: PlanStore
    private let router: AppRouter

    init(context: ModelContext, categories: CategoryRepositing, planStore: PlanStore, router: AppRouter) {
        self.context = context
        self.categories = categories
        self.planStore = planStore
        self.router = router
    }

    func reset() {
        // Children go with their parents through the cascade rules, but deleting
        // every type explicitly keeps this correct even if a relationship changes.
        // A type that fails to delete must not stop the rest, or the store would be
        // left half-empty and inconsistent.
        try? context.delete(model: ExpenseEntity.self)
        try? context.delete(model: DebtPaymentEntity.self)
        try? context.delete(model: DebtEntity.self)
        try? context.delete(model: UtilityReadingEntity.self)
        try? context.delete(model: UtilityEntity.self)
        try? context.delete(model: SubscriptionEntity.self)
        try? context.delete(model: FixedExpenseEntity.self)
        try? context.delete(model: IncomeEntity.self)
        try? context.delete(model: GoalEntity.self)
        try? context.delete(model: ReviewLogEntity.self)
        try? context.delete(model: CategoryEntity.self)
        try? context.delete(model: ProfileEntity.self)
        try? context.save()

        // A store with no categories cannot produce a plan, so the defaults are
        // part of an empty store rather than something setup adds.
        categories.seedDefaultsIfNeeded()

        planStore.refresh()
        router.restart()
    }
}
