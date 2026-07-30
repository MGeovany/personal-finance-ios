import Foundation

/// Highest interest rate first — the cheapest order in total interest, which is
/// why the app recommends it by default.
struct AvalanchePrioritizer: DebtPrioritizing {
    func order(_ debts: [DebtSnapshot]) -> [DebtSnapshot] {
        debts.sorted { lhs, rhs in
            if lhs.annualRate != rhs.annualRate { return lhs.annualRate > rhs.annualRate }
            // Same rate: clearing the smaller one frees its minimum sooner.
            return lhs.balance < rhs.balance
        }
    }
}
