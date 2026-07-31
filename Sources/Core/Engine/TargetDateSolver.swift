import Foundation

/// Takes the date the user wants and works backwards to the payment, the weekly
/// budget, the cuts, the savings and the paused goals it would require.
///
/// The feasibility question is asked at the tightest tuning available. The point
/// is to know whether the date is possible *at all*, not whether it fits the plan
/// the user currently has.
struct TargetDateSolver: TargetDateSolving {
    private let cashFlowCalculating: CashFlowCalculating
    private let emergencyAdvising: EmergencyFundAdvising
    private let lifestyleBudgeting: LifestyleBudgeting
    private let projecting: DebtProjecting
    private let weeklySplitting: WeeklyBudgetSplitting
    private let difficultyRating: DifficultyRating
    private let search: PaymentSearch
    private let calendar: Calendar

    init(
        cashFlowCalculating: CashFlowCalculating = CashFlowCalculator(),
        emergencyAdvising: EmergencyFundAdvising = EmergencyFundAdvisor(),
        lifestyleBudgeting: LifestyleBudgeting = LifestyleBudgetAllocator(),
        projecting: DebtProjecting = DebtProjector(),
        weeklySplitting: WeeklyBudgetSplitting = WeeklyBudgetSplitter(),
        difficultyRating: DifficultyRating = DifficultyRater(),
        search: PaymentSearch = PaymentSearch(),
        calendar: Calendar = Calendar.current
    ) {
        self.cashFlowCalculating = cashFlowCalculating
        self.emergencyAdvising = emergencyAdvising
        self.lifestyleBudgeting = lifestyleBudgeting
        self.projecting = projecting
        self.weeklySplitting = weeklySplitting
        self.difficultyRating = difficultyRating
        self.search = search
        self.calendar = calendar
    }

    func assess(targetDate: Date, request: PlanRequest) -> TargetDateAssessment {
        let snapshot = request.snapshot
        let from = snapshot.referenceDate
        // The tightest tuning: minimal cushion, deepest allowed cuts.
        let tuning = PlanTuning.forSpeed(.aggressive)

        let emergency = emergencyAdvising.advise(for: snapshot, tuning: tuning)
        let cashFlow = cashFlowCalculating.cashFlow(for: snapshot, emergencyContribution: emergency.monthlyContribution)
        let floors = lifestyleBudgeting.allocate(categories: snapshot.flexibleCategories, tuning: tuning, ceiling: 0)
        let floorTotal = floors.allocations.totalMonthly
        let maxExtra = (cashFlow.available - floorTotal).nonNegative

        let solution = solve(
            targetDate: targetDate,
            snapshot: snapshot,
            strategy: request.strategy,
            maxExtra: maxExtra,
            from: from
        )

        let allowedVariable = (cashFlow.available - solution.extra).nonNegative
        let fitted = lifestyleBudgeting.allocate(
            categories: snapshot.flexibleCategories,
            tuning: tuning,
            ceiling: allowedVariable
        )
        let weekly = weeklySplitting.split(monthly: fitted.allocations.totalMonthly, containing: from)

        let allocation = SurplusAllocation(
            categories: fitted.allocations,
            buffer: 0,
            goalFundingByID: [:],
            extraDebtPayment: solution.extra,
            freeMargin: 0,
            shortfall: fitted.shortfall
        )

        return TargetDateAssessment(
            requestedDate: targetDate,
            isAchievable: solution.isAchievable,
            requiredMonthlyPayment: (cashFlow.minimumPayments + solution.extra).rounded,
            allowedMonthlyVariable: fitted.allocations.totalMonthly,
            allowedWeeklyVariable: weekly.averageWeekly,
            requiredCuts: cuts(from: snapshot, to: fitted.allocations),
            savingsNeeded: solution.lumpSum,
            goalsToPause: goalsToPause(snapshot: snapshot, allowedVariable: allowedVariable, extra: solution.extra, available: cashFlow.available),
            difficulty: difficultyRating.rate(allocation: allocation, cashFlow: cashFlow, snapshot: snapshot),
            totalInterest: solution.projection?.totalInterest ?? 0,
            earliestAchievableDate: solution.earliestDate
        )
    }

    // MARK: - Solving

    private struct Solution {
        let extra: Money
        let lumpSum: Money
        let isAchievable: Bool
        let earliestDate: Date?
        let projection: DebtProjection?
    }

    /// Tries to hit the date with monthly payments alone; only then considers
    /// savings, because draining savings should be a conscious extra step.
    private func solve(
        targetDate: Date,
        snapshot: FinancialSnapshot,
        strategy: PayoffStrategy,
        maxExtra: Money,
        from: Date
    ) -> Solution {
        guard snapshot.hasDebt else {
            return Solution(extra: 0, lumpSum: 0, isAchievable: true, earliestDate: from, projection: .debtFree)
        }

        let reaches: (Money, Money) -> Bool = { extra, lump in
            guard let date = self.projecting
                .project(debts: snapshot.debts, extraPayment: extra, lumpSum: lump, strategy: strategy, from: from)
                .freedomDate
            else { return false }
            return date <= targetDate
        }

        if let extra = search.smallestAmount(upTo: maxExtra, succeeds: { reaches($0, 0) }) {
            let projection = projecting.project(debts: snapshot.debts, extraPayment: extra, lumpSum: 0, strategy: strategy, from: from)
            return Solution(extra: extra, lumpSum: 0, isAchievable: true, earliestDate: projection.freedomDate, projection: projection)
        }

        if let lump = search.smallestAmount(upTo: snapshot.savings, succeeds: { reaches(maxExtra, $0) }) {
            let projection = projecting.project(debts: snapshot.debts, extraPayment: maxExtra, lumpSum: lump, strategy: strategy, from: from)
            return Solution(extra: maxExtra, lumpSum: lump, isAchievable: true, earliestDate: projection.freedomDate, projection: projection)
        }

        // Out of reach: report the earliest date that everything available buys.
        let best = projecting.project(
            debts: snapshot.debts,
            extraPayment: maxExtra,
            lumpSum: snapshot.savings,
            strategy: strategy,
            from: from
        )
        return Solution(extra: maxExtra, lumpSum: 0, isAchievable: false, earliestDate: best.freedomDate, projection: best)
    }

    // MARK: - Consequences

    private func cuts(from snapshot: FinancialSnapshot, to allocations: [CategoryAllocation]) -> [CategoryCut] {
        allocations.compactMap { allocation in
            guard let category = snapshot.flexibleCategories.first(where: { $0.key == allocation.key }),
                  allocation.monthly < category.realisticBaseline
            else { return nil }

            return CategoryCut(
                categoryKey: allocation.key,
                categoryName: allocation.name,
                from: category.realisticBaseline,
                to: allocation.monthly
            )
        }
    }

    private func goalsToPause(
        snapshot: FinancialSnapshot,
        allowedVariable: Money,
        extra: Money,
        available: Money
    ) -> [String] {
        let leftForGoals = (available - allowedVariable - extra).nonNegative
        let funded = snapshot.goals.filter { $0.effectiveMonthly > 0 }
        guard leftForGoals < funded.reduce(Money.zero, { $0 + $1.effectiveMonthly }) else { return [] }
        return funded.map(\.name)
    }
}
