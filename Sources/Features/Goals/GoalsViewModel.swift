import Foundation
import Observation

/// The goals screen, and the trade-off each goal represents.
@MainActor
@Observable
final class GoalsViewModel {
    private let goals: GoalRepositing
    private let savings: SavingsRepositing
    private let planStore: PlanStore
    private let dateProvider: DateProviding

    init(
        goals: GoalRepositing,
        savings: SavingsRepositing,
        planStore: PlanStore,
        dateProvider: DateProviding = SystemDateProvider()
    ) {
        self.goals = goals
        self.savings = savings
        self.planStore = planStore
        self.dateProvider = dateProvider
    }

    var currency: CurrencyCode { planStore.currency }
    var plan: FinancialPlan { planStore.activePlan }
    var hasDebt: Bool { planStore.snapshot.hasDebt }

    var allGoals: [GoalEntity] { goals.all() }

    var totalMonthlyFunding: Money { plan.allocation.goalFunding }

    func impact(for goal: GoalEntity) -> GoalImpact? {
        plan.goalImpacts.first { $0.goalID == goal.uuid }
    }

    func funding(for goal: GoalEntity) -> Money {
        plan.allocation.funding(for: goal.uuid)
    }

    /// What switching a goal's pace would do, so the choice is never blind.
    func impact(ofChanging goal: GoalEntity, to mode: GoalMode) -> PlanImpact {
        planStore.impact(of: .changeGoalMode(id: goal.uuid, mode: mode)).impact
    }

    func setMode(_ mode: GoalMode, for goal: GoalEntity) {
        goal.mode = mode
        goals.save()
        planStore.refresh()
    }

    func add(_ draft: GoalDraft) {
        goals.add(draft.makeEntity(priority: allGoals.count))
        planStore.refresh()
    }

    func update(_ draft: GoalDraft) {
        guard let entity = goals.goal(withID: draft.id) else { return }
        draft.apply(to: entity)
        goals.save()
        planStore.refresh()
    }

    func delete(_ goal: GoalEntity) {
        goals.delete(goal)
        planStore.refresh()
    }

    func contribute(_ amount: Money, to goal: GoalEntity) {
        // Through the savings ledger rather than the goal repository, so the transfer is
        // dated and the payday card can see it happened.
        savings.contribute(amount, to: goal, on: dateProvider.now, note: "")
        planStore.refresh()
    }
}
