import Foundation

/// Turns a snapshot into "what is actually available this month".
protocol CashFlowCalculating: Sendable {
    func cashFlow(
        for snapshot: FinancialSnapshot,
        emergencyContribution: Money
    ) -> CashFlow
}
