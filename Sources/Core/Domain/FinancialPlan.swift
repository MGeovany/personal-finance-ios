import Foundation

/// A complete answer to "what should I do with my money this month, and when
/// does this end?". the single object every screen reads from.
struct FinancialPlan: Identifiable, Equatable, Sendable {
    let speed: PlanSpeed
    /// Editable, so it comes from storage rather than from `speed.defaultName`.
    let name: String
    let strategy: PayoffStrategy
    let cashFlow: CashFlow
    let allocation: SurplusAllocation
    let emergency: EmergencyFundAdvice
    let projection: DebtProjection
    let weekly: WeeklyBudget
    let grocery: GroceryPlan
    let goalImpacts: [GoalImpact]
    let difficulty: PlanDifficulty
    /// Debts in the order the extra payment will attack them.
    let attackOrder: [UUID]
    let warnings: [PlanWarning]

    var id: PlanSpeed { speed }

    /// Minimums plus the extra payment: the number the user should send this month.
    var monthlyDebtPayment: Money {
        cashFlow.minimumPayments + allocation.extraDebtPayment
    }

    var freedomDate: Date? { projection.freedomDate }
    var monthsToFreedom: Int? { projection.monthsToFreedom }
    var totalInterest: Money { projection.totalInterest }

    /// Everyday spending money for the month.
    var monthlyVariableBudget: Money { allocation.variableSpending }

    /// Money that frees up the month the last debt is gone.
    var monthlyMoneyAfterFreedom: Money {
        monthlyDebtPayment + allocation.goalFunding
    }

    /// The debt the extra payment goes to right now.
    var nextTargetDebtID: UUID? { attackOrder.first }

    var isFeasible: Bool { projection.isFeasible && !cashFlow.isDeficit }

    var delayedGoals: [GoalImpact] { goalImpacts.filter(\.delaysPlan) }

    var criticalWarnings: [PlanWarning] {
        warnings.filter { $0.severity == .critical }
    }

    func budget(forCategoryKey key: String) -> Money {
        allocation.categories.allocation(forKey: key)?.monthly ?? 0
    }
}
