import Foundation

/// Measures each goal's cost in days by asking a simple question: what would the
/// freedom date be if this goal's money went to the debt instead?
///
/// That is the number the user needs to make the call, and it is honest because
/// it comes from the same projector the plan itself uses.
struct GoalImpactCalculator: GoalImpactCalculating {
    private let projector: DebtProjecting
    private let calendar: Calendar

    init(projector: DebtProjecting = DebtProjector(), calendar: Calendar = Calendar.current) {
        self.projector = projector
        self.calendar = calendar
    }

    func impacts(
        snapshot: FinancialSnapshot,
        allocation: SurplusAllocation,
        strategy: PayoffStrategy,
        baselineProjection: DebtProjection,
        from date: Date
    ) -> [GoalImpact] {
        snapshot.goals.map { goal in
            let funded = allocation.funding(for: goal.id)

            return GoalImpact(
                goalID: goal.id,
                goalName: goal.name,
                mode: goal.mode,
                fundedMonthly: funded,
                requestedMonthly: goal.requestedMonthly,
                daysDelayed: daysDelayed(
                    by: funded,
                    snapshot: snapshot,
                    allocation: allocation,
                    strategy: strategy,
                    baseline: baselineProjection,
                    from: date
                ),
                projectedCompletion: completionDate(for: goal, funded: funded, from: date)
            )
        }
    }

    private func daysDelayed(
        by funded: Money,
        snapshot: FinancialSnapshot,
        allocation: SurplusAllocation,
        strategy: PayoffStrategy,
        baseline: DebtProjection,
        from date: Date
    ) -> Int {
        guard funded > 0, snapshot.hasDebt, let baselineDate = baseline.freedomDate else { return 0 }

        let withoutGoal = projector.project(
            debts: snapshot.debts,
            extraPayment: allocation.extraDebtPayment + funded,
            strategy: strategy,
            from: date
        )
        guard let fasterDate = withoutGoal.freedomDate else { return 0 }

        return max(0, calendar.days(from: fasterDate, to: baselineDate))
    }

    /// Straight-line: at this contribution, when does the goal fill up?
    private func completionDate(for goal: GoalSnapshot, funded: Money, from date: Date) -> Date? {
        guard funded > 0, goal.remaining > 0 else { return goal.isComplete ? date : nil }
        let months = Int(ceil((goal.remaining / funded).doubleValue))
        return calendar.addingMonths(months, to: date)
    }
}
