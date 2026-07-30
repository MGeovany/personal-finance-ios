import Foundation

/// Works out what each secondary goal costs in payoff time.
protocol GoalImpactCalculating: Sendable {
    /// - Parameter baselineMonths: months to freedom with the goals funded as
    ///   the plan intends, used as the reference to measure the delay against.
    func impacts(
        snapshot: FinancialSnapshot,
        allocation: SurplusAllocation,
        strategy: PayoffStrategy,
        baselineProjection: DebtProjection,
        from date: Date
    ) -> [GoalImpact]
}
