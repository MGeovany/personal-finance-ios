import Foundation

/// Cuts everyday budgets in the order a person actually would: dining out and
/// entertainment first, groceries and transport last, and never below the floor
/// that makes a category livable.
///
/// The buffer and reserved categories are excluded here. The buffer is sized
/// from the surplus and reserves have exact amounts of their own.
struct LifestyleBudgetAllocator: LifestyleBudgeting {
    func allocate(
        categories: [CategoryBaseline],
        tuning: PlanTuning,
        ceiling: Money
    ) -> (allocations: [CategoryAllocation], shortfall: Money) {
        let eligible = categories.filter { $0.flexibility == .essential || $0.flexibility == .discretionary }
        guard !eligible.isEmpty else { return ([], (0 - ceiling).nonNegative) }

        var targets: [UUID: Money] = [:]
        var floors: [UUID: Money] = [:]

        for category in eligible {
            // A pinned category is exactly what the user asked for: the plan's
            // speed does not scale it and the cut passes never touch it.
            if let pinned = category.override {
                floors[category.id] = pinned
                targets[category.id] = pinned
                continue
            }

            let base = category.realisticBaseline
            let squeeze = category.flexibility == .discretionary
                ? tuning.lifestyleFactor * tuning.discretionaryFactor
                : tuning.lifestyleFactor
            let floor = base.scaled(by: category.flexibility.floorFactor).rounded
            floors[category.id] = floor
            targets[category.id] = max(base.scaled(by: squeeze).rounded, floor)
        }

        let requested = targets.values.reduce(Money.zero, +)
        var shortfall = Money.zero

        if requested > ceiling {
            var excess = requested - ceiling
            // Discretionary first: the plan should protect food and transport.
            excess = reduce(&targets, floors: floors, in: eligible.filter { $0.flexibility == .discretionary }, by: excess)
            excess = reduce(&targets, floors: floors, in: eligible.filter { $0.flexibility == .essential }, by: excess)
            // Everything is at its floor and the money still does not reach.
            shortfall = excess
        }

        let allocations = eligible
            .sorted { $0.order < $1.order }
            .map { category in
                CategoryAllocation(
                    id: category.id,
                    key: category.key,
                    name: category.name,
                    icon: category.icon,
                    flexibility: category.flexibility,
                    monthly: targets[category.id] ?? 0,
                    baseline: category.baseline
                )
            }

        return (allocations, shortfall)
    }

    /// Takes `excess` out of the given categories in proportion to how much room
    /// each has above its floor, and returns what could not be taken.
    private func reduce(
        _ targets: inout [UUID: Money],
        floors: [UUID: Money],
        in categories: [CategoryBaseline],
        by excess: Money
    ) -> Money {
        guard excess > 0, !categories.isEmpty else { return excess }

        let room = categories.reduce(Money.zero) { total, category in
            total + ((targets[category.id] ?? 0) - (floors[category.id] ?? 0)).nonNegative
        }
        guard room > 0 else { return excess }

        let take = min(excess, room)
        let ratio = (take / room).doubleValue

        for category in categories {
            let current = targets[category.id] ?? 0
            let floor = floors[category.id] ?? 0
            let categoryRoom = (current - floor).nonNegative
            targets[category.id] = (current - categoryRoom.scaled(by: ratio)).rounded
        }

        return excess - take
    }
}
