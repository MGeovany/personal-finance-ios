import Foundation

/// Subtracts every unavoidable commitment from income.
///
/// Money already reserved for card purchases is treated as committed: the user
/// promised it to a statement, so offering it again would be a lie.
struct CashFlowCalculator: CashFlowCalculating {
    func cashFlow(
        for snapshot: FinancialSnapshot,
        emergencyContribution: Money
    ) -> CashFlow {
        CashFlow(
            income: snapshot.totalIncome,
            fixedExpenses: snapshot.fixedExpenses.totalMonthly + snapshot.reservedForCards,
            utilities: snapshot.utilities.totalMonthly,
            subscriptions: snapshot.subscriptions.totalMonthly,
            minimumPayments: snapshot.totalMinimumPayments,
            emergencyContribution: emergencyContribution
        )
    }
}
