import Foundation

/// The answer to "how much money is actually mine to decide about this month?"
struct CashFlow: Equatable, Sendable {
    let income: Money
    let fixedExpenses: Money
    let utilities: Money
    let subscriptions: Money
    let minimumPayments: Money
    let emergencyContribution: Money
    /// Money set aside for card statements already incurred.
    ///
    /// Deliberately *not* part of `committed`: those purchases were already
    /// recorded as expenses against their categories, so charging them again here
    /// would count the same money twice. And a one-off reservation is not a
    /// monthly obligation, so it must not shrink every future month either.
    let reservedForCards: Money

    var committed: Money {
        fixedExpenses + utilities + subscriptions + minimumPayments + emergencyContribution
    }

    /// What is left to distribute each month. Negative means the month does not
    /// close, which the app must say out loud rather than hide behind a plan.
    var available: Money { income - committed }

    /// Available right now, once money promised to a statement is set aside. This
    /// is a display figure for the current month, never an input to the projection.
    var availableAfterReservations: Money { available - reservedForCards }

    var isDeficit: Bool { available < 0 }

    var deficit: Money { available < 0 ? -available : 0 }

    /// Share of income already spoken for, useful as a single health indicator.
    var commitmentRatio: Double {
        guard income > 0 else { return 1 }
        return min(1, (committed / income).doubleValue)
    }
}
