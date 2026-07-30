import Foundation

/// Shares a pot of money between goals in proportion to what each asked for.
///
/// Its own type because both the allocator and the target-date solver need the
/// same split, and because "fair share" is a rule worth stating once.
struct GoalFundingDistributor: Sendable {
    func distribute(_ total: Money, among goals: [GoalSnapshot]) -> [UUID: Money] {
        let requests = goals.filter { $0.effectiveMonthly > 0 }
        let requested = requests.reduce(Money.zero) { $0 + $1.effectiveMonthly }
        guard requested > 0, total > 0 else { return [:] }

        // Enough for everyone: nobody gets scaled down.
        if total >= requested {
            return Dictionary(uniqueKeysWithValues: requests.map { ($0.id, $0.effectiveMonthly) })
        }

        let ratio = (total / requested).doubleValue
        return Dictionary(
            uniqueKeysWithValues: requests.map { ($0.id, $0.effectiveMonthly.scaled(by: ratio).rounded) }
        )
    }
}
