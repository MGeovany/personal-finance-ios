import Foundation

/// Decides which debt the extra payment attacks next.
///
/// One implementation per strategy: adding a new way to order debts means adding
/// a type, not editing the projector.
protocol DebtPrioritizing: Sendable {
    /// Debts ordered by attack priority, highest first.
    func order(_ debts: [DebtSnapshot]) -> [DebtSnapshot]
}
