import Foundation

/// Rewrites a plan request as if a decision had been taken.
///
/// Every case here is a pure value transformation, which is the whole trick
/// behind the simulator: the same `PlanBuilder` that produced the real plan
/// produces the hypothetical one, so the two are always comparable.
struct ScenarioApplier: ScenarioApplying {
    func apply(_ mutations: [ScenarioMutation], to request: PlanRequest) -> PlanRequest {
        mutations.reduce(request) { current, mutation in apply(one: mutation, to: current) }
    }

    private func apply(one mutation: ScenarioMutation, to request: PlanRequest) -> PlanRequest {
        var result = request

        switch mutation {
        case .cancelSubscription(let id):
            result.snapshot.subscriptions.removeAll { $0.id == id }

        case .changeCategoryBudget(let key, let amount):
            result.snapshot.categories = request.snapshot.categories.map {
                $0.key == key ? $0.pinning(amount) : $0
            }

        case .useSavings(let amount):
            let used = min(amount, request.snapshot.savings)
            result.snapshot.savings -= used
            result.lumpSumFromSavings += used

        case .extraIncome(let amount, let recurring):
            if recurring {
                result.snapshot.otherIncome += amount
            } else {
                result.lumpSumFromSavings += amount
            }

        case .oneTimePayment(let amount, let debtID):
            if let debtID {
                result.snapshot.debts = request.snapshot.debts.map { debt in
                    debt.id == debtID ? debt.updating(balance: (debt.balance - amount).nonNegative) : debt
                }
            } else {
                result.lumpSumFromSavings += amount
            }

        case .addGoal(let name, let monthly, let target):
            result.snapshot.goals.append(
                GoalSnapshot(
                    id: UUID(),
                    name: name,
                    targetAmount: target,
                    savedAmount: 0,
                    requestedMonthly: monthly,
                    targetDate: nil,
                    mode: .parallel,
                    priority: request.snapshot.goals.count
                )
            )

        case .changeGoalMode(let id, let mode):
            result.snapshot.goals = request.snapshot.goals.map {
                $0.id == id ? $0.updating(mode: mode) : $0
            }

        case .cardPurchase(let amount, let debtID, let backed):
            if backed {
                // The money exists but is promised to a statement: it stops being
                // available without becoming debt.
                result.snapshot.reservedForCards += amount
            } else {
                result.snapshot.debts = request.snapshot.debts.map { debt in
                    debt.id == debtID ? debt.updating(balance: debt.balance + amount) : debt
                }
            }

        case .changeStrategy(let strategy):
            result.strategy = strategy

        case .changeSpeed(let speed):
            result = request.with(speed: speed)
        }

        return result
    }
}
