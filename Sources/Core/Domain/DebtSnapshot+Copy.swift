import Foundation

/// Copy helpers. The projector walks balances down month by month and the
/// simulator rewrites terms hypothetically; both need a changed copy, never a
/// mutated original.
extension DebtSnapshot {
    func updating(balance: Money) -> DebtSnapshot {
        var copy = self
        copy.balance = balance
        return copy
    }

    func updating(status: DebtStatus) -> DebtSnapshot {
        var copy = self
        copy.status = status
        return copy
    }

    func updating(manualPriority: Int) -> DebtSnapshot {
        var copy = self
        copy.manualPriority = manualPriority
        return copy
    }
}
