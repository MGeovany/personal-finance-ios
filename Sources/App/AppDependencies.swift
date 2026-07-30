import Foundation
import Observation
import SwiftData

/// The composition root: the one place that knows which concrete type implements
/// each protocol.
///
/// Everything else receives what it needs. That is what makes the engine testable
/// without a database and the views previewable without a plan. Observable only so
/// it can travel through the SwiftUI environment.
@MainActor
@Observable
final class AppDependencies {
    let container: ModelContainer

    let profiles: ProfileProviding
    let incomes: IncomeRepositing
    let fixedExpenses: FixedExpenseRepositing
    let utilities: UtilityRepositing
    let subscriptions: SubscriptionRepositing
    let debts: DebtRepositing
    let categories: CategoryRepositing
    let goals: GoalRepositing
    let expenses: ExpenseRepositing
    let reviews: ReviewRepositing

    let planStore: PlanStore
    let preferences: PlanPreferencing
    let notifications: PlanNotificationScheduling

    let money: MoneyFormatting
    let dates: PlanDateFormatting
    let monthKeys: MonthKeyFormatter

    init(container: ModelContainer, notifications: PlanNotificationScheduling = PlanNotificationScheduler()) {
        self.container = container
        let context = container.mainContext

        let profiles = ProfileRepository(context: context)
        let expenses = ExpenseRepository(context: context)
        let categories = CategoryRepository(context: context)

        // The default categories must exist before the first snapshot is built,
        // otherwise the first plan would have nothing to budget.
        categories.seedDefaultsIfNeeded()

        self.profiles = profiles
        self.expenses = expenses
        self.categories = categories
        self.incomes = IncomeRepository(context: context)
        self.fixedExpenses = FixedExpenseRepository(context: context)
        self.utilities = UtilityRepository(context: context)
        self.subscriptions = SubscriptionRepository(context: context)
        self.debts = DebtRepository(context: context)
        self.goals = GoalRepository(context: context)
        self.reviews = ReviewRepository(context: context)
        self.notifications = notifications

        let assembler = SnapshotAssembler(
            profiles: profiles,
            incomes: incomes,
            fixedExpenses: fixedExpenses,
            utilities: utilities,
            subscriptions: subscriptions,
            debts: debts,
            categories: categories,
            goals: goals,
            expenses: expenses,
            history: CategoryHistoryCalculator(expenses: expenses)
        )

        let planStore = PlanStore(assembler: assembler, profiles: profiles)
        self.planStore = planStore
        self.preferences = ProfileSettingsService(profiles: profiles, planStore: planStore)

        self.money = MoneyFormatter()
        self.dates = PlanDateFormatter()
        self.monthKeys = MonthKeyFormatter()
    }

    var profile: ProfileEntity { profiles.profile() }

    var currency: CurrencyCode { profile.currency }

    /// Writes Spanish sentences about the current plan.
    var narrator: PlanNarrator {
        PlanNarrator(money: money, dates: dates, currency: currency)
    }

    var warnings: PlanWarningPresenter {
        PlanWarningPresenter(money: money, dates: dates, currency: currency)
    }

    static func live() -> AppDependencies {
        // A store that cannot be opened leaves the app with nowhere to put data;
        // an in-memory fallback keeps it usable and visibly empty rather than
        // crashing on launch.
        let container = (try? ModelSchema.container()) ?? (try! ModelSchema.inMemoryContainer())
        let dependencies = AppDependencies(container: container)

        if DemoDataSeeder.isRequested {
            dependencies.seedDemoData()
        }
        return dependencies
    }

    /// Only reachable through the `CERO_DEMO_DATA` launch variable.
    func seedDemoData() {
        DemoDataSeeder(
            profiles: profiles,
            fixedExpenses: fixedExpenses,
            utilities: utilities,
            subscriptions: subscriptions,
            debts: debts,
            categories: categories,
            goals: goals,
            expenses: expenses,
            planStore: planStore
        )
        .seedIfNeeded()
    }

    static func preview() -> AppDependencies {
        AppDependencies(container: try! ModelSchema.inMemoryContainer(), notifications: NoopNotificationScheduler())
    }
}
