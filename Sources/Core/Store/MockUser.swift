import Foundation

/// A saved sample situation: one household with three debts, services,
/// subscriptions, a goal and a few days of spending.
///
/// Never loaded on its own. It has to be asked for. With `CERO_MOCK_USER=1` at
/// launch, or from the developer section in settings. So the app a real user
/// opens is always empty and theirs to fill.
@MainActor
struct MockUser {
    /// Shown wherever the fixture is offered, so it is obvious what is being loaded.
    static let name = "Usuario de prueba"
    static let summary = "Ingreso L45,000 · tres deudas por L175,500 · servicios, suscripciones, una meta y gastos recientes"

    private let profiles: ProfileProviding
    private let fixedExpenses: FixedExpenseRepositing
    private let utilities: UtilityRepositing
    private let subscriptions: SubscriptionRepositing
    private let debts: DebtRepositing
    private let categories: CategoryRepositing
    private let goals: GoalRepositing
    private let expenses: ExpenseRepositing
    private let savings: SavingsRepositing
    private let planStore: PlanStore

    /// Whether this launch asked for the sample user.
    static var isRequestedAtLaunch: Bool {
        ProcessInfo.processInfo.environment["CERO_MOCK_USER"] == "1"
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
        savings: SavingsRepositing,
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
        self.savings = savings
        self.planStore = planStore
    }

    /// Loads the sample situation, but only into an empty store: it must never
    /// overwrite something the user typed.
    func loadIfStoreIsEmpty(now: Date = Date()) {
        guard debts.all().isEmpty else { return }

        seedProfile()
        seedCommitments()
        seedDebts()
        seedBaselines()
        seedGoal()
        seedRecentExpenses(now: now)
        seedHistory(now: now)

        planStore.refresh()
    }

    private func seedProfile() {
        let profile = profiles.profile()
        // The fixture stands in for somebody who finished setup, and setup asks for
        // a name, so the screens that greet the user have something to greet.
        profile.displayName = "Ana"
        profile.currency = .hnl
        profile.primaryIncome = 45_000
        profile.emergencyFund = 6_100
        profile.savings = 25_000
        profile.groceryMode = .hybrid
        // Paid on the 15th and the last day, which is what "quincenal" means here and
        // what most salaried people in Honduras are on.
        profile.paydaySchedule = .semimonthlyDefault
        // Six weeks in, with the debt it started at, so the progress screen has a
        // baseline to measure against.
        profile.planStartedAt = Calendar.current.date(byAdding: .day, value: -42, to: Date())
        profile.debtAtPlanStart = 189_000
        profile.hasCompletedOnboarding = true
        // The sample user exists to inspect screens, so it must not trigger the
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
                name: "BAC Visa Signature",
                institution: "BAC",
                kind: .creditCard,
                balance: 69_000,
                creditLimit: 80_000,
                annualRate: 0.48,
                minimumPayment: 3_100,
                statementDay: 25,
                dueDay: 15
            )
        )
        debts.add(
            DebtEntity(
                name: "Ficohsa Visa Gold",
                institution: "Ficohsa",
                kind: .creditCard,
                balance: 20_000,
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
                institution: "Atlántida",
                kind: .carLoan,
                balance: 100_000,
                annualRate: 0.14,
                minimumPayment: 4_200,
                dueDay: 20
            )
        )
    }

    private func seedBaselines() {
        let baselines: [String: Money] = [
            CategoryKeys.groceries: 6_000,
            CategoryKeys.delivery: 1_500,
            CategoryKeys.online: 1_200,
            CategoryKeys.transport: 2_500,
            CategoryKeys.outings: 3_000,
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
                savedAmount: 3_000,
                requestedMonthly: 4_000,
                mode: .parallel
            )
        )
    }

    /// Six weeks of abonos, so the progress screen has something to measure.
    ///
    /// Registered through the repositories rather than written as totals, which is what
    /// makes the balances land on today's figures and the dated ledgers agree with them.
    private func seedHistory(now: Date) {
        let calendar = Calendar.current
        let all = debts.all()

        let payments: [(name: String, days: Int, amount: Money)] = [
            ("BAC Visa Signature", 38, 3_500),
            ("BAC Visa Signature", 8, 3_500),
            ("Ficohsa Visa Gold", 38, 1_500),
            ("Préstamo carro", 23, 5_000),
        ]

        for payment in payments {
            guard let debt = all.first(where: { $0.name == payment.name }) else { continue }
            debts.registerPayment(
                payment.amount,
                on: debt,
                date: calendar.addingDays(-payment.days, to: now),
                note: "",
                wasRecommended: true
            )
        }

        savings.contributeToEmergencyFund(1_900, on: calendar.addingDays(-38, to: now), note: "")
        if let goal = goals.all().first {
            savings.contribute(2_000, to: goal, on: calendar.addingDays(-23, to: now), note: "")
        }
    }

    /// A few days of spending, so budgets show progress rather than untouched bars.
    private func seedRecentExpenses(now: Date) {
        let calendar = Calendar.current
        let entries: [(days: Int, amount: Money, merchant: String, key: String, method: PaymentMethod)] = [
            (0, 450, "La Colonia", CategoryKeys.groceries, .cash),
            (0, 180, "Uber", CategoryKeys.transport, .debit),
            (1, 320, "Pedidos Ya", CategoryKeys.delivery, .cash),
            (2, 1_250, "Super", CategoryKeys.groceries, .debit),
            (3, 890, "Amazon", CategoryKeys.online, .creditCard),
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
