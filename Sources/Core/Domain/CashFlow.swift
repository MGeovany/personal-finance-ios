import Foundation

/// The answer to "how much money is actually mine to decide about this month?"
struct CashFlow: Equatable, Sendable {
    let income: Money
    let fixedExpenses: Money
    let utilities: Money
    let subscriptions: Money
    let minimumPayments: Money
    let emergencyContribution: Money

    var committed: Money {
        fixedExpenses + utilities + subscriptions + minimumPayments + emergencyContribution
    }

    /// What is left to distribute. Negative means the month does not close, which
    /// the app must say out loud rather than hide behind a plan.
    var available: Money { income - committed }

    var isDeficit: Bool { available < 0 }

    var deficit: Money { available < 0 ? -available : 0 }

    /// Share of income already spoken for, useful as a single health indicator.
    var commitmentRatio: Double {
        guard income > 0 else { return 1 }
        return min(1, (committed / income).doubleValue)
    }
}
