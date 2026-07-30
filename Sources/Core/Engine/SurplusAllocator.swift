import Foundation

/// Distributes the available money in a fixed order of precedence:
/// goals the user explicitly prioritised, then everyday life, then the buffer,
/// remaining goals and free margin — and whatever survives all of that becomes
/// the extra debt payment.
///
/// Putting debt last is deliberate: it absorbs every improvement automatically,
/// so cancelling a subscription or underspending a category shortens the plan
/// without any extra bookkeeping.
struct SurplusAllocator: SurplusAllocating {
    private let lifestyleBudgeting: LifestyleBudgeting
    private let goalDistributor: GoalFundingDistributor
    /// Ceiling on prioritised goals, so a goal can never starve the essentials.
    private let priorityGoalCap: Double

    init(
        lifestyleBudgeting: LifestyleBudgeting = LifestyleBudgetAllocator(),
        goalDistributor: GoalFundingDistributor = GoalFundingDistributor(),
        priorityGoalCap: Double = 0.4
    ) {
        self.lifestyleBudgeting = lifestyleBudgeting
        self.goalDistributor = goalDistributor
        self.priorityGoalCap = priorityGoalCap
    }

    func allocate(
        available: Money,
        snapshot: FinancialSnapshot,
        tuning: PlanTuning
    ) -> SurplusAllocation {
        let usable = available.nonNegative

        let priorityGoals = snapshot.goals.filter { $0.mode.isFundedBeforeDebt }
        let priorityBudget = min(request(from: priorityGoals), usable.scaled(by: priorityGoalCap)).rounded
        let priorityFunding = goalDistributor.distribute(priorityBudget, among: priorityGoals)
        let afterPriorityGoals = (usable - priorityFunding.total).nonNegative

        let lifestyle = lifestyleBudgeting.allocate(
            categories: snapshot.flexibleCategories,
            tuning: tuning,
            ceiling: afterPriorityGoals
        )
        let remaining = (afterPriorityGoals - lifestyle.allocations.totalMonthly).nonNegative

        let buffer = remaining.scaled(by: tuning.bufferShare).rounded
        let otherGoals = snapshot.goals.filter { !$0.mode.isFundedBeforeDebt }
        let otherFunding = goalDistributor.distribute(
            remaining.scaled(by: tuning.goalShare).rounded,
            among: otherGoals
        )
        let freeMarginShare = remaining.scaled(by: tuning.freeMarginShare).rounded

        let leftover = (remaining - buffer - otherFunding.total - freeMarginShare).nonNegative
        // With no debt to attack, the leftover is the user's to keep rather than a
        // payment the app invents.
        let extraDebt = snapshot.hasDebt ? leftover : 0
        let freeMargin = snapshot.hasDebt ? freeMarginShare : freeMarginShare + leftover

        return SurplusAllocation(
            categories: withBuffer(buffer, into: lifestyle.allocations, snapshot: snapshot),
            buffer: buffer,
            goalFundingByID: priorityFunding.merging(otherFunding) { first, _ in first },
            extraDebtPayment: extraDebt,
            freeMargin: freeMargin,
            shortfall: lifestyle.shortfall
        )
    }

    private func request(from goals: [GoalSnapshot]) -> Money {
        goals.reduce(Money.zero) { $0 + $1.effectiveMonthly }
    }

    /// The buffer is a real category on screen, so it joins the allocation list
    /// with the amount the plan decided rather than a declared baseline.
    private func withBuffer(
        _ buffer: Money,
        into allocations: [CategoryAllocation],
        snapshot: FinancialSnapshot
    ) -> [CategoryAllocation] {
        guard let bufferCategory = snapshot.visibleCategories.first(where: { $0.flexibility == .buffer }) else {
            return allocations
        }
        let entry = CategoryAllocation(
            id: bufferCategory.id,
            key: bufferCategory.key,
            name: bufferCategory.name,
            icon: bufferCategory.icon,
            flexibility: .buffer,
            monthly: buffer,
            baseline: bufferCategory.baseline
        )
        return allocations + [entry]
    }
}

private extension Dictionary where Key == UUID, Value == Money {
    var total: Money { values.reduce(Money.zero, +) }
}
