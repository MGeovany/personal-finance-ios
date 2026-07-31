import Foundation

/// Translates a plan into what it allows, order by order and weekend by weekend.
protocol PlanBriefingBuilding: Sendable {
    /// - Parameter typicalDeliveryOrder: what one order has actually cost this user, when
    ///   there is enough history to know. Nil falls back to a default, and the briefing
    ///   says which of the two happened.
    func build(
        from plan: FinancialPlan,
        snapshot: FinancialSnapshot,
        typicalDeliveryOrder: Money?
    ) -> PlanBriefing
}
