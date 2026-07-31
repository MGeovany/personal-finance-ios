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
    ///
    /// When two debts share a rank in `attackOrder`, the lower balance comes
    /// first so the list matches snowball intuition and stays stable.
    var orderedDebts: [DebtEntity] {
        let all = debts.all()
        let order = plan.attackOrder
        let active = all
            .filter { $0.status.participatesInProjection && $0.balance > 0 }
            .sorted { lhs, rhs in
                let left = order.firstIndex(of: lhs.uuid) ?? Int.max
                let right = order.firstIndex(of: rhs.uuid) ?? Int.max
                if left != right { return left < right }
                if lhs.balance != rhs.balance { return lhs.balance < rhs.balance }
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
        let settled = all
            .filter { $0.status.isSettled || $0.balance == 0 }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        return active + settled
    }

    var targetDebtID: UUID? { plan.nextTargetDebtID }

    /// 1-based rank for active debts in attack order. Settled debts get no rank.
    func attackRank(for debt: DebtEntity, at index: Int) -> Int? {
        guard debt.status.participatesInProjection, debt.balance > 0 else { return nil }
        return index + 1
    }

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
