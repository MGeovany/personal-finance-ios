import Foundation

/// Smallest balance first — costs a little more in interest, but debts disappear
/// sooner, which for many people is what keeps the plan alive.
struct SnowballPrioritizer: DebtPrioritizing {
    func order(_ debts: [DebtSnapshot]) -> [DebtSnapshot] {
        debts.sorted { lhs, rhs in
            if lhs.balance != rhs.balance { return lhs.balance < rhs.balance }
            return lhs.annualRate > rhs.annualRate
        }
    }
}
