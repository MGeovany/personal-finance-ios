import Foundation

/// Fills an empty store with a plausible situation.
///
/// Only ever runs when the app is launched with `CERO_DEMO_DATA=1`, so it cannot
/// touch a real user's data. Its purpose is to make the screens inspectable —
/// during development, in screenshots, and in previews — without typing a full
/// setup by hand every time.
@MainActor
struct DemoDataSeeder {
    private let profiles: ProfileProviding
    private let fixedExpenses: FixedExpenseRepositing
    private let utilities: UtilityRepositing
    private let subscriptions: SubscriptionRepositing
    private let debts: DebtRepositing
    private let categories: CategoryRepositing
    private let goals: GoalRepositing
    private let expenses: ExpenseRepositing
    private let planStore: PlanStore

    /// Whether the current launch asked for demo data.
    static var isRequested: Bool {
        ProcessInfo.processInfo.environment["CERO_DEMO_DATA"] == "1"
    }

    init(
        profiles: ProfileProviding,
        fixedExpenses: FixedExpenseRepositing,
        utilities: UtilityRepositing,
        subscriptions: SubscriptionRepositing,
        debts: DebtRepositing,
        categories: CategoryRepositing,
        goals: GoalRepositing,
        expenses: ExpenseRepositing,
        planStore: PlanStore
    ) {
        self.profiles = profiles
        self.fixedExpenses = fixedExpenses
        self.utilities = utilities
        self.subscriptions = subscriptions
        self.debts = debts
        self.categories = categories
        self.goals = goals
        self.expenses = expenses
        self.planStore = planStore
    }

    /// Seeds only when there is nothing there, so relaunching does not duplicate.
    func seedIfNeeded(now: Date = Date()) {
        guard debts.all().isEmpty else { return }

        seedProfile()
        seedCommitments()
        seedDebts()
        seedBaselines()
        seedGoal()
        seedRecentExpenses(now: now)

        planStore.refresh()
    }

    private func seedProfile() {
        let profile = profiles.profile()
        profile.currency = .hnl
        profile.primaryIncome = 45_000
        profile.emergencyFund = 8_000
        profile.savings = 25_000
        profile.groceryMode = .hybrid
        profile.hasCompletedOnboarding = true
        // Demo launches are for inspecting screens, so they must not trigger the
        // system permission prompt.
        profile.notificationsEnabled = false
        profiles.save()
    }

    private func seedCommitments() {
        fixedExpenses.add(FixedExpenseEntity(name: "Alquiler", amount: 9_000, dueDay: 1))

        for (index, utility) in [("Luz", Money(1_800), 12), ("Agua", Money(400), 8), ("Internet", Money(900), 5)].enumerated() {
            utilities.add(
                UtilityEntity(
                    name: utility.0,
                    icon: UtilityIcon.suggestion(for: utility.0),
                    estimatedAmount: utility.1,
                    dueDay: utility.2,
                    order: index
                )
            )
        }

        subscriptions.add(SubscriptionEntity(name: "Streaming", amount: 500, chargeDay: 14, isNecessary: false))
        subscriptions.add(SubscriptionEntity(name: "Almacenamiento", amount: 250, chargeDay: 3))
    }

    private func seedDebts() {
        debts.add(
            DebtEntity(
                name: "Tarjeta Azul",
                institution: "Banco Atlántida",
                kind: .creditCard,
                balance: 62_000,
                creditLimit: 80_000,
                annualRate: 0.48,
                minimumPayment: 3_100,
                statementDay: 25,
                dueDay: 15
            )
        )
        debts.add(
            DebtEntity(
                name: "Tarjeta Oro",
                institution: "BAC",
                kind: .creditCard,
                balance: 18_500,
                creditLimit: 30_000,
                annualRate: 0.32,
                minimumPayment: 950,
                statementDay: 20,
                dueDay: 5
            )
        )
        debts.add(
            DebtEntity(
                name: "Préstamo carro",
                institution: "Ficohsa",
                kind: .carLoan,
                balance: 95_000,
                annualRate: 0.14,
                minimumPayment: 4_200,
                dueDay: 20
            )
        )
    }

    private func seedBaselines() {
        let baselines: [String: Money] = [
            CategoryKeys.groceries: 6_000,
            CategoryKeys.transport: 2_500,
            CategoryKeys.outings: 3_000,
            CategoryKeys.restaurants: 2_000,
            CategoryKeys.health: 800,
            CategoryKeys.unexpected: 1_500,
        ]

        for (key, amount) in baselines {
            categories.category(forKey: key)?.baseline = amount
        }
        categories.save()
    }

    private func seedGoal() {
        goals.add(
            GoalEntity(
                name: "Viaje",
                icon: "airplane",
                targetAmount: 40_000,
                savedAmount: 5_000,
                requestedMonthly: 4_000,
                mode: .parallel
            )
        )
    }

    /// A few days of spending, so budgets show progress rather than untouched bars.
    private func seedRecentExpenses(now: Date) {
        let calendar = Calendar.current
        let entries: [(days: Int, amount: Money, merchant: String, key: String, method: PaymentMethod)] = [
            (0, 450, "La Colonia", CategoryKeys.groceries, .cash),
            (0, 180, "Uber", CategoryKeys.transport, .debit),
            (1, 620, "Cena", CategoryKeys.restaurants, .cash),
            (2, 1_250, "Supermercado", CategoryKeys.groceries, .debit),
            (3, 300, "Farmacia", CategoryKeys.pharmacy, .cash),
            (4, 900, "Salida", CategoryKeys.outings, .cash),
        ]

        for entry in entries {
            expenses.add(
                ExpenseEntity(
                    amount: entry.amount,
                    date: calendar.addingDays(-entry.days, to: now),
                    merchant: entry.merchant,
                    categoryKey: entry.key,
                    paymentMethod: entry.method
                )
            )
        }
    }
}
