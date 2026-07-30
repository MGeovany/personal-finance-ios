import Foundation

/// Everything needed to build one plan, as a value.
///
/// Grouping the inputs keeps `PlanBuilding` a one-argument protocol: new options
/// are added here without changing any signature.
struct PlanRequest: Equatable, Sendable {
    var snapshot: FinancialSnapshot
    var speed: PlanSpeed
    /// The plan's display name, which the user can edit.
    var name: String
    var strategy: PayoffStrategy
    var groceryMode: GroceryMode
    var groceryMainShare: Double
    /// One-off amount from savings the user agreed to throw at the debt. Zero
    /// unless they accepted the suggestion — the plan never assumes it.
    var lumpSumFromSavings: Money

    var tuning: PlanTuning { PlanTuning.forSpeed(speed) }

    init(
        snapshot: FinancialSnapshot,
        speed: PlanSpeed,
        name: String? = nil,
        strategy: PayoffStrategy = .recommended,
        groceryMode: GroceryMode = .recommended,
        groceryMainShare: Double = GroceryMode.recommended.defaultMainShare,
        lumpSumFromSavings: Money = 0
    ) {
        self.snapshot = snapshot
        self.speed = speed
        self.name = name ?? speed.defaultName
        self.strategy = strategy
        self.groceryMode = groceryMode
        self.groceryMainShare = groceryMainShare
        self.lumpSumFromSavings = lumpSumFromSavings
    }

    func with(speed: PlanSpeed, name: String? = nil) -> PlanRequest {
        var copy = self
        copy.speed = speed
        copy.name = name ?? speed.defaultName
        return copy
    }

    func with(snapshot: FinancialSnapshot) -> PlanRequest {
        var copy = self
        copy.snapshot = snapshot
        return copy
    }
}
