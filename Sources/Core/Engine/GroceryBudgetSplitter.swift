import Foundation

/// Turns a monthly grocery budget into the shape the user actually shops in.
///
/// Hybrid is the recommended mode: one main purchase for what keeps, plus weekly
/// top-ups for fresh food. The user can move the proportion, and whatever is not
/// in the main run is spread evenly across the remaining weeks.
struct GroceryBudgetSplitter: GroceryBudgetSplitting {
    func split(monthly: Money, mode: GroceryMode, mainShare: Double, weeks: Int) -> GroceryPlan {
        let weekCount = max(1, weeks)

        switch mode {
        case .monthly:
            return GroceryPlan(mode: mode, monthly: monthly, mainPurchase: monthly, weeklyRestock: 0, restockWeeks: 0)

        case .weekly:
            let weekly = (monthly / weekCount).rounded
            return GroceryPlan(mode: mode, monthly: monthly, mainPurchase: 0, weeklyRestock: weekly, restockWeeks: weekCount)

        case .hybrid:
            let share = min(0.9, max(0.1, mainShare))
            let main = monthly.scaled(by: share).rounded
            let weekly = ((monthly - main) / weekCount).rounded
            return GroceryPlan(mode: mode, monthly: monthly, mainPurchase: main, weeklyRestock: weekly, restockWeeks: weekCount)
        }
    }
}
