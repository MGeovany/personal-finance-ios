import Foundation
import Observation

/// The weekly and monthly closes.
///
/// One view model for both because they ask the same question — what happened, and
/// what do we do with what is left — over different windows.
@MainActor
@Observable
final class PeriodCloseViewModel {
    private let expenses: ExpenseRepositing
    private let debts: DebtRepositing
    private let goals: GoalRepositing
    private let profiles: ProfileProviding
    private let reviews: ReviewRepositing
    private let progress: BudgetProgressCalculating
    private let planStore: PlanStore
    private let dateProvider: DateProviding

    let kind: ReviewKind
    var surplusDestination: SurplusDestination

    init(
        kind: ReviewKind,
        expenses: ExpenseRepositing,
        debts: DebtRepositing,
        goals: GoalRepositing,
        profiles: ProfileProviding,
        reviews: ReviewRepositing,
        progress: BudgetProgressCalculating,
        planStore: PlanStore,
        dateProvider: DateProviding = SystemDateProvider()
    ) {
        self.kind = kind
        self.expenses = expenses
        self.debts = debts
        self.goals = goals
        self.profiles = profiles
        self.reviews = reviews
        self.progress = progress
        self.planStore = planStore
        self.dateProvider = dateProvider
        self.surplusDestination = SurplusDestination.recommended(
            hasHighInterestDebt: planStore.snapshot.highestAnnualRate >= 0.20
        )
    }

    var currency: CurrencyCode { planStore.currency }
    var plan: FinancialPlan { planStore.activePlan }
    private var now: Date { dateProvider.now }

    /// Budget versus spending over the period being closed.
    var consumption: BudgetConsumption {
        kind == .weekly ? progress.weekTotal(plan: plan, on: now) : progress.monthTotal(plan: plan, on: now)
    }

    var surplus: Money { consumption.remaining }

    /// Categories ranked by spend, so the biggest one is obvious.
    var categoryBreakdown: [BudgetConsumption] {
        progress.monthlyProgress(plan: plan, on: now)
            .filter { $0.spent > 0 }
            .sorted { $0.spent > $1.spent }
    }

    var biggestCategory: BudgetConsumption? { categoryBreakdown.first }

    var overspentCategories: [BudgetConsumption] {
        categoryBreakdown.filter(\.isOverBudget)
    }

    /// Payments made during the period.
    var payments: [DebtPaymentEntity] {
        let start = periodStart
        return debts.all()
            .flatMap(\.payments)
            .filter { $0.date >= start }
            .sorted { $0.date > $1.date }
    }

    var totalPaid: Money {
        payments.reduce(Money.zero) { $0 + $1.amount }
    }

    // MARK: - Monthly close figures

    var income: Money { planStore.snapshot.totalIncome }
    var fixedCosts: Money { planStore.snapshot.fixedExpenses.totalMonthly }
    var utilities: Money { planStore.snapshot.utilities.totalMonthly }
    var subscriptions: Money { planStore.snapshot.subscriptions.totalMonthly }
    var variableSpending: Money { progress.monthTotal(plan: plan, on: now).spent }
    var interestThisMonth: Money {
        planStore.snapshot.activeDebts.reduce(Money.zero) { $0 + $1.monthlyInterestCost }
    }
    var emergencyFund: Money { planStore.snapshot.emergencyFund }
    var goalFunding: Money { plan.allocation.goalFunding }
    var debtChange: Money { totalPaid - interestThisMonth }

    /// The plan's own estimate, kept so the close can compare intention to result.
    var estimatedDate: Date? { plan.freedomDate }

    var recommendation: String {
        if consumption.isOverBudget {
            return "Te pasaste del presupuesto. La próxima semana el plan baja un poco el margen para compensar, sin cambiar tu fecha."
        }
        if surplus > 0 {
            return "Cerraste con dinero de sobra. Mientras tengas deuda con intereses altos, abonarla es lo que más te ahorra."
        }
        return "Cerraste justo en el presupuesto."
    }

    var isComplete: Bool { reviews.isComplete(kind, on: now) }

    /// Places the leftover money and records the close.
    func complete() {
        applySurplus()
        reviews.complete(
            kind,
            on: now,
            checkedExternalApps: false,
            surplusDestination: surplusDestination,
            surplusAmount: surplus
        )
        planStore.refresh()
    }

    private func applySurplus() {
        guard surplus > 0 else { return }

        switch surplusDestination {
        case .debt:
            guard let targetID = plan.nextTargetDebtID, let debt = debts.debt(withID: targetID) else { return }
            debts.registerPayment(surplus, on: debt, date: now, note: "Sobrante del cierre", wasRecommended: false)

        case .emergencyFund:
            let profile = profiles.profile()
            profile.emergencyFund += surplus
            profiles.save()

        case .goal:
            guard let goal = goals.active().first else { return }
            goals.contribute(surplus, to: goal, on: now)

        // Carrying over means leaving it exactly where it is.
        case .carryOver:
            break
        }
    }

    private var periodStart: Date {
        let calendar = dateProvider.calendar
        switch kind {
        case .weekly:
            return plan.weekly.week(containing: now)?.start ?? calendar.addingDays(-7, to: now)
        case .monthly, .daily:
            return calendar.startOfMonth(for: now)
        }
    }
}
