import Foundation

/// Finds the slack that would pay for a bigger budget.
///
/// Takes from the discretionary categories first, in proportion to how much room each has
/// above its floor, which is the same order the plans themselves cut in. Only when those
/// run out does it touch what the goals receive, because a goal is something the user chose
/// and a dinner out is not.
///
/// Essentials are never touched. Paying for more delivery by cutting groceries is the kind
/// of advice that gets an app deleted.
struct BudgetRebalancer: BudgetRebalancing {
    func rebalance(
        raising key: String,
        to amount: Money,
        in plan: FinancialPlan,
        snapshot: FinancialSnapshot
    ) -> BudgetRebalance {
        let current = plan.budget(forCategoryKey: key)
        let needed = (amount - current).nonNegative
        guard needed > 0 else { return .none }

        let sources = slack(excluding: key, in: plan, snapshot: snapshot)
        let available = sources.reduce(Money.zero) { $0 + $1.slack }

        let fromCategories = min(needed, available)
        let cuts = distribute(fromCategories, across: sources)

        let remaining = needed - fromCategories
        let fromGoals = min(remaining, plan.allocation.goalFunding)

        return BudgetRebalance(
            needed: needed,
            cuts: cuts,
            fromGoals: fromGoals,
            shortfall: (remaining - fromGoals).nonNegative
        )
    }

    // MARK: - Where the room is

    private struct Source {
        let allocation: CategoryAllocation
        let floor: Money

        var slack: Money { (allocation.monthly - floor).nonNegative }
    }

    private func slack(excluding key: String, in plan: FinancialPlan, snapshot: FinancialSnapshot) -> [Source] {
        plan.allocation.categories
            .filter { $0.key != key && $0.flexibility == .discretionary }
            .compactMap { allocation in
                guard let baseline = snapshot.categories.first(where: { $0.key == allocation.key }) else { return nil }
                let source = Source(allocation: allocation, floor: baseline.floor)
                return source.slack > 0 ? source : nil
            }
            // Largest first, so the cuts land where they are least felt per lempira.
            .sorted { $0.slack > $1.slack }
    }

    /// Shares the amount across the sources in proportion to their slack, so no single
    /// category absorbs the whole increase.
    private func distribute(_ total: Money, across sources: [Source]) -> [CategoryCut] {
        guard total > 0, !sources.isEmpty else { return [] }

        let available = sources.reduce(Money.zero) { $0 + $1.slack }
        guard available > 0 else { return [] }

        var remaining = total

        return sources.enumerated().compactMap { index, source in
            let isLast = index == sources.count - 1
            // The last one absorbs the rounding remainder, so the cuts add up exactly to
            // what the increase needed.
            let share = isLast
                ? min(remaining, source.slack)
                : min(remaining, source.slack.scaled(by: (total / available).doubleValue).rounded)

            guard share > 0 else { return nil }
            remaining -= share

            return CategoryCut(
                categoryKey: source.allocation.key,
                categoryName: source.allocation.name,
                from: source.allocation.monthly,
                to: source.allocation.monthly - share
            )
        }
    }
}
