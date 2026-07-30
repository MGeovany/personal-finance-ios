import Foundation

/// Subtracts every unavoidable monthly commitment from income.
///
/// Money reserved for card statements is carried through untouched rather than
/// subtracted: those purchases were already recorded against their category
/// budgets, and a reservation settled this month is not an obligation that repeats.
struct CashFlowCalculator: CashFlowCalculating {
    func cashFlow(
        for snapshot: FinancialSnapshot,
        emergencyContribution: Money
    ) -> CashFlow {
        CashFlow(
            income: snapshot.totalIncome,
            fixedExpenses: snapshot.fixedExpenses.totalMonthly,
            utilities: snapshot.utilities.totalMonthly,
            subscriptions: snapshot.subscriptions.totalMonthly,
            minimumPayments: snapshot.totalMinimumPayments,
            emergencyContribution: emergencyContribution,
            reservedForCards: snapshot.reservedForCards
        )
    }
}
