import Foundation

/// The order the user pinned. Debts without a pinned position fall to the end,
/// ordered by rate so the default behind the user's choices stays sensible.
struct CustomPrioritizer: DebtPrioritizing {
    func order(_ debts: [DebtSnapshot]) -> [DebtSnapshot] {
        debts.sorted { lhs, rhs in
            let left = lhs.manualPriority
            let right = rhs.manualPriority
            let leftPinned = left > 0
            let rightPinned = right > 0

            if leftPinned != rightPinned { return leftPinned }
            if leftPinned, left != right { return left < right }
            return lhs.annualRate > rhs.annualRate
        }
    }
}
