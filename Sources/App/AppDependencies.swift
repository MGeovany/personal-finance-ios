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
    let savings: SavingsRepositing

    let planStore: PlanStore
    let preferences: PlanPreferencing
    let notifications: PlanNotificationScheduling
    let router: AppRouter
    let storeResetting: StoreResetting

    let money: MoneyFormatting
    let dates: PlanDateFormatting
    let monthKeys: MonthKeyFormatter
    /// Held as the concrete type because the composition root is the one place that is
    /// allowed to know it, and because refreshing is not something a view converting an
    /// amount should be able to ask for.
    let exchangeRates: LiveExchangeRateProvider

    init(
        container: ModelContainer,
        notifications: PlanNotificationScheduling = PlanNotificationScheduler(),
        exchangeRates: LiveExchangeRateProvider = LiveExchangeRateProvider()
    ) {
        self.container = container
        self.exchangeRates = exchangeRates
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
        self.savings = SavingsRepository(context: context, profiles: profiles)
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
            history: CategoryHistoryCalculator(expenses: expenses),
            rates: exchangeRates
        )

        let planStore = PlanStore(assembler: assembler, profiles: profiles)
        self.planStore = planStore
        self.preferences = ProfileSettingsService(profiles: profiles, planStore: planStore)

        let router = AppRouter(hasCompletedOnboarding: profiles.profile().hasCompletedOnboarding)
        self.router = router
        self.storeResetting = StoreResetter(
            context: context,
            categories: categories,
            planStore: planStore,
            router: router
        )

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

    /// Translates the active plan into what it allows: orders, weekends, the card that
    /// gets attacked. Recomputed on every read, so it follows an edited budget.
    var briefingProvider: PlanBriefingProviding {
        PlanBriefingProvider(
            planStore: planStore,
            history: CategoryHistoryCalculator(expenses: expenses)
        )
    }

    var briefingPresenter: PlanBriefingPresenter {
        PlanBriefingPresenter(money: money, dates: dates, currency: currency)
    }

    /// One history, merged from the expense, payment and savings ledgers.
    var activityFeed: ActivityFeedProviding {
        ActivityFeedProvider(
            expenses: expenses,
            debts: debts,
            savings: savings,
            goals: goals,
            categories: categories,
            profiles: profiles
        )
    }

    /// How the plan is actually going, measured against the day it started.
    var planProgress: PlanProgressProviding {
        PlanProgressProvider(
            profiles: profiles,
            debts: debts,
            savings: savings,
            planStore: planStore
        )
    }

    /// Where the user stands relative to their payday, which decides what the dashboard
    /// leads with and which reminders are worth sending.
    var paydayStatus: PaydayStatusProviding {
        PaydayStatusProvider(
            profiles: profiles,
            debts: debts,
            savings: savings,
            briefings: briefingProvider
        )
    }

    /// Rebuilds every pending reminder from the plan as it stands.
    ///
    /// Called at launch and again after an abono is registered, because the nudges about
    /// a missed payday cannot know on their own that they are no longer needed: they are
    /// booked one per day and thrown away by this rebuild.
    func refreshReminders() async {
        let profile = self.profile
        guard profile.notificationsEnabled else {
            await notifications.cancelAll()
            return
        }
        guard await notifications.requestAuthorization() else { return }

        let plan = planStore.activePlan
        let status = paydayStatus

        await notifications.reschedule(
            for: plan,
            snapshot: planStore.snapshot,
            reminder: DailyReminder(
                hour: profile.reminderHour,
                minute: profile.reminderMinute,
                isEnabled: profile.notificationsEnabled
            ),
            payday: status.schedule.map { schedule in
                PaydayReminder(
                    schedule: schedule,
                    status: status.status,
                    totalToDebt: plan.monthlyDebtPayment,
                    toSavings: plan.emergency.monthlyContribution,
                    currency: currency,
                    now: Date()
                )
            }
        )
    }

    static func live() -> AppDependencies {
        // A store that cannot be opened leaves the app with nowhere to put data;
        // an in-memory fallback keeps it usable and visibly empty rather than
        // crashing on launch.
        let container = (try? ModelSchema.container()) ?? (try! ModelSchema.inMemoryContainer())
        let dependencies = AppDependencies(container: container)

        if MockUser.isRequestedAtLaunch {
            dependencies.loadMockUser()
        }
        return dependencies
    }

    /// Loads the saved sample situation into an empty store. Asked for explicitly:
    /// through `CERO_MOCK_USER=1` at launch, or from the developer section in
    /// settings. A normal launch never calls this.
    func loadMockUser() {
        MockUser(
            profiles: profiles,
            fixedExpenses: fixedExpenses,
            utilities: utilities,
            subscriptions: subscriptions,
            debts: debts,
            categories: categories,
            goals: goals,
            expenses: expenses,
            savings: savings,
            planStore: planStore
        )
        .loadIfStoreIsEmpty()

        if profile.hasCompletedOnboarding {
            router.phase = .main
        }
    }

    static func preview() -> AppDependencies {
        AppDependencies(
            container: try! ModelSchema.inMemoryContainer(),
            notifications: NoopNotificationScheduler(),
            // A preview must not reach the network or touch the cache, so it converts
            // with the bundled table and stays there.
            exchangeRates: LiveExchangeRateProvider(
                fetcher: OfflineExchangeRateFetcher(),
                store: EphemeralExchangeRateStore()
            )
        )
    }
}
