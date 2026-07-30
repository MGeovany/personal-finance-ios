import Foundation

/// The monthly amount a plan assigns to one category.
struct CategoryAllocation: Identifiable, Equatable, Sendable {
    let id: UUID
    let key: String
    let name: String
    let icon: String
    let flexibility: CategoryFlexibility
    let monthly: Money
    /// What the user declared, kept alongside so the UI can show the cut.
    let baseline: Money

    /// Negative when the plan is asking for a cut, positive when it is being
    /// more generous than the user expected.
    var difference: Money { monthly - baseline }

    var cutFraction: Double {
        guard baseline > 0 else { return 0 }
        return max(0, 1 - (monthly / baseline).doubleValue)
    }

    var isCut: Bool { monthly < baseline }
}

extension Array where Element == CategoryAllocation {
    var totalMonthly: Money {
        reduce(Money.zero) { $0 + $1.monthly }
    }

    func allocation(forKey key: String) -> CategoryAllocation? {
        first { $0.key == key }
    }
}
