import Foundation
import Observation

/// The debt list and the strategy behind its order.
@MainActor
@Observable
final class DebtsViewModel {
    private let debts: DebtRepositing
    private let planStore: PlanStore
    private let preferences: PlanPreferencing

    init(debts: DebtRepositing, planStore: PlanStore, preferences: PlanPreferencing) {
        self.debts = debts
        self.planStore = planStore
        self.preferences = preferences
    }

    var plan: FinancialPlan { planStore.activePlan }
    var currency: CurrencyCode { planStore.currency }
    var strategy: PayoffStrategy { plan.strategy }

    var totalDebt: Money { planStore.snapshot.totalDebt }
    var totalMinimums: Money { planStore.snapshot.totalMinimumPayments }
    var extraPayment: Money { plan.allocation.extraDebtPayment }

    /// Outstanding debts in the plan's attack order, then the settled ones.
    var orderedDebts: [DebtEntity] {
        let all = debts.all()
        let order = plan.attackOrder
        let active = all
            .filter { $0.status.participatesInProjection && $0.balance > 0 }
            .sorted { lhs, rhs in
                let left = order.firstIndex(of: lhs.uuid) ?? Int.max
                let right = order.firstIndex(of: rhs.uuid) ?? Int.max
                return left < right
            }
        let settled = all.filter { $0.status.isSettled || $0.balance == 0 }
        return active + settled
    }

    var targetDebtID: UUID? { plan.nextTargetDebtID }

    func payoffDate(for debt: DebtEntity) -> Date? {
        plan.projection.payoffDateByDebt[debt.uuid]
    }

    /// The payment this debt should receive: its minimum, plus the extra if it is
    /// the one being attacked.
    func recommendedPayment(for debt: DebtEntity) -> Money {
        debt.uuid == targetDebtID ? debt.minimumPayment + extraPayment : debt.minimumPayment
    }

    /// Interest saved by the current strategy versus the alternative, so switching
    /// is an informed choice.
    func interestDifference(switchingTo strategy: PayoffStrategy) -> Money {
        planStore.impact(of: .changeStrategy(strategy)).impact.interestSaved
    }

    func select(strategy: PayoffStrategy) {
        preferences.select(strategy: strategy)
    }

    func add(_ draft: DebtDraft) {
        debts.add(draft.makeEntity())
        planStore.refresh()
    }

    func update(_ draft: DebtDraft) {
        guard let entity = debts.debt(withID: draft.id) else { return }
        draft.apply(to: entity)
        debts.save()
        planStore.refresh()
    }

    func delete(_ debt: DebtEntity) {
        debts.delete(debt)
        planStore.refresh()
    }

    /// Pins the order for the custom strategy.
    func setPriority(_ priority: Int, for debt: DebtEntity) {
        debt.manualPriority = priority
        debts.save()
        planStore.refresh()
    }
}
