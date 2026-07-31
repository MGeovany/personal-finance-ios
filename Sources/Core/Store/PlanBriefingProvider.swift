import Foundation

/// Hands out the current briefing, always derived from the plan as it stands now.
///
/// Deliberately not cached. Editing the grocery budget from 7,000 to 3,200 recalculates
/// the plan, and the briefing has to be recalculated with it: a stored copy is how the
/// dashboard would end up promising four deliveries a month after the money for them
/// was moved somewhere else.
@MainActor
protocol PlanBriefingProviding {
    var briefing: PlanBriefing { get }
}

@MainActor
struct PlanBriefingProvider: PlanBriefingProviding {
    private let planStore: PlanStore
    private let history: CategoryHistoryCalculating
    private let builder: PlanBriefingBuilding
    private let dateProvider: DateProviding

    init(
        planStore: PlanStore,
        history: CategoryHistoryCalculating,
        builder: PlanBriefingBuilding = PlanBriefingBuilder(),
        dateProvider: DateProviding = SystemDateProvider()
    ) {
        self.planStore = planStore
        self.history = history
        self.builder = builder
        self.dateProvider = dateProvider
    }

    var briefing: PlanBriefing {
        builder.build(
            from: planStore.activePlan,
            snapshot: planStore.snapshot,
            typicalDeliveryOrder: history.typicalExpense(
                inCategory: CategoryKeys.delivery,
                before: dateProvider.now,
                minimumSamples: 3
            )
        )
    }
}
