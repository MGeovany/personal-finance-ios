import Foundation

/// Splits the grocery budget between one big run and weekly top-ups.
protocol GroceryBudgetSplitting: Sendable {
    func split(monthly: Money, mode: GroceryMode, mainShare: Double, weeks: Int) -> GroceryPlan
}
