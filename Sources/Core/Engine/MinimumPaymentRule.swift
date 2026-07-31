import Foundation

/// Works out what a debt must receive this month for the balance to actually move.
///
/// Users often enter a minimum payment that barely covers interest, which would
/// make the projection run forever. The rule keeps the stated minimum whenever it
/// makes progress, and otherwise raises it to interest plus a slice of principal . 
/// the same way card issuers compute theirs.
struct MinimumPaymentRule: Sendable {
    /// Principal fraction added on top of interest when the stated minimum is
    /// too small to reduce the balance.
    private let principalFloor: Double

    init(principalFloor: Double = 0.01) {
        self.principalFloor = principalFloor
    }

    /// - Parameter balance: balance after this month's interest was added.
    func minimum(for debt: DebtSnapshot, balance: Money) -> Money {
        guard balance > 0 else { return 0 }
        let progressing = balance.scaled(by: debt.monthlyRate + principalFloor)
        return min(balance, max(debt.minimumPayment, progressing))
    }
}
