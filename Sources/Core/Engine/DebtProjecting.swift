import Foundation

/// Simulates paying the debts off month by month.
protocol DebtProjecting: Sendable {
    /// - Parameters:
    ///   - extraPayment: amount on top of every minimum, sent to the priority debt.
    ///   - lumpSum: one-off payment applied in the first month, e.g. From savings.
    func project(
        debts: [DebtSnapshot],
        extraPayment: Money,
        lumpSum: Money,
        strategy: PayoffStrategy,
        from date: Date
    ) -> DebtProjection
}

extension DebtProjecting {
    func project(
        debts: [DebtSnapshot],
        extraPayment: Money,
        strategy: PayoffStrategy,
        from date: Date
    ) -> DebtProjection {
        project(debts: debts, extraPayment: extraPayment, lumpSum: 0, strategy: strategy, from: date)
    }
}
