import Foundation

/// Assigns a monthly amount to every everyday category, given how much there is
/// to go around and how hard the plan wants to squeeze.
protocol LifestyleBudgeting: Sendable {
    /// - Parameter ceiling: the most that may be spent on lifestyle in total.
    /// - Returns: per-category amounts plus any shortfall the ceiling could not
    ///   cover even after cutting every category to its floor.
    func allocate(
        categories: [CategoryBaseline],
        tuning: PlanTuning,
        ceiling: Money
    ) -> (allocations: [CategoryAllocation], shortfall: Money)
}
