import Foundation

/// Reads every repository once and produces one snapshot.
///
/// Two rules are enforced here rather than left to the engine: every amount is
/// converted to the user's main currency, and money already reserved for card
/// statements is carried as reserved so it can never be offered as available.
@MainActor
struct SnapshotAssembler: SnapshotAssembling {
    private let profiles: ProfileProviding
    private let incomes: IncomeRepositing
    private let fixedExpenses: FixedExpenseRepositing
    private let utilities: UtilityRepositing
    private let subscriptions: SubscriptionRepositing
    private let debts: DebtRepositing
    private let categories: CategoryRepositing
    private let goals: GoalRepositing
    private let expenses: ExpenseRepositing
    private let history: CategoryHistoryCalculating
    private let rates: ExchangeRateProviding

    init(
        profiles: ProfileProviding,
        incomes: IncomeRepositing,
        fixedExpenses: FixedExpenseRepositing,
        utilities: UtilityRepositing,
        subscriptions: SubscriptionRepositing,
        debts: DebtRepositing,
        categories: CategoryRepositing,
        goals: GoalRepositing,
        expenses: ExpenseRepositing,
        history: CategoryHistoryCalculating,
        rates: ExchangeRateProviding = StaticExchangeRateProvider()
    ) {
        self.profiles = profiles
        self.incomes = incomes
        self.fixedExpenses = fixedExpenses
        self.utilities = utilities
        self.subscriptions = subscriptions
        self.debts = debts
        self.categories = categories
        self.goals = goals
        self.expenses = expenses
        self.history = history
        self.rates = rates
    }

    func snapshot(referenceDate: Date) -> FinancialSnapshot {
        let profile = profiles.profile()
        let base = profile.currency
        let averages = history.monthlyAverages(before: referenceDate)

        return FinancialSnapshot(
            currency: base,
            primaryIncome: profile.primaryIncome,
            otherIncome: incomes.active().reduce(Money.zero) { total, income in
                total + convert(income.monthlyAmount, income.currency, base)
            },
            fixedExpenses: fixedExpenses.active().map { expense in
                RecurringCharge(
                    id: expense.uuid,
                    name: expense.name,
                    monthlyAmount: convert(expense.monthlyAmount, expense.currency, base),
                    dueDay: expense.dueDay
                )
            },
            utilities: utilities.active().map { utility in
                RecurringCharge(
                    id: utility.uuid,
                    name: utility.name,
                    monthlyAmount: convert(utility.monthlyReserve, utility.currency, base),
                    dueDay: utility.dueDay
                )
            },
            subscriptions: subscriptions.charging().map { subscription in
                RecurringCharge(
                    id: subscription.uuid,
                    name: subscription.name,
                    monthlyAmount: convert(subscription.monthlyCost, subscription.currency, base),
                    dueDay: subscription.chargeDay,
                    isNecessary: subscription.isNecessary
                )
            },
            debts: debts.all().map { debt in
                DebtSnapshot(
                    id: debt.uuid,
                    name: debt.name,
                    institution: debt.institution,
                    kind: debt.kind,
                    balance: convert(debt.balance, debt.currency, base),
                    creditLimit: debt.creditLimit.map { convert($0, debt.currency, base) },
                    annualRate: debt.annualRate,
                    minimumPayment: convert(debt.minimumPayment, debt.currency, base),
                    statementDay: debt.statementDay,
                    dueDay: debt.dueDay,
                    status: debt.status,
                    manualPriority: debt.manualPriority
                )
            },
            categories: categories.all().map { category in
                CategoryBaseline(
                    id: category.uuid,
                    key: category.key,
                    name: category.name,
                    icon: category.icon,
                    baseline: category.baseline,
                    flexibility: category.flexibility,
                    historicalAverage: averages[category.key],
                    isHidden: category.isHidden,
                    order: category.order,
                    override: category.budgetOverride
                )
            },
            goals: goals.active().map { goal in
                GoalSnapshot(
                    id: goal.uuid,
                    name: goal.name,
                    targetAmount: convert(goal.targetAmount, goal.currency, base),
                    savedAmount: convert(goal.savedAmount, goal.currency, base),
                    requestedMonthly: convert(goal.requestedMonthly, goal.currency, base),
                    targetDate: goal.targetDate,
                    mode: goal.mode,
                    priority: goal.priority
                )
            },
            emergencyFund: profile.emergencyFund,
            savings: profile.savings,
            reservedForCards: expenses.totalReservedForCards(),
            referenceDate: referenceDate
        )
    }

    func planRequest(referenceDate: Date) -> PlanRequest {
        let profile = profiles.profile()
        return PlanRequest(
            snapshot: snapshot(referenceDate: referenceDate),
            speed: profile.selectedSpeed,
            name: profile.name(for: profile.selectedSpeed),
            strategy: profile.strategy,
            groceryMode: profile.groceryMode,
            groceryMainShare: profile.groceryMainShare
        )
    }

    private func convert(_ amount: Money, _ from: CurrencyCode, _ to: CurrencyCode) -> Money {
        rates.convert(amount, from: from, to: to)
    }
}
