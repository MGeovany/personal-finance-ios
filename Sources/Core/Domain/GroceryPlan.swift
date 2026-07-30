import Foundation

/// How the user prefers to buy groceries.
enum GroceryMode: String, CaseIterable, Codable, Identifiable, Sendable {
    /// Fresh produce, tighter control, more trips.
    case weekly
    /// Bulk buying, fewer trips, more money committed at once.
    case monthly
    /// One big monthly run plus small weekly top-ups. The recommendation.
    case hybrid

    var id: String { rawValue }

    var label: String {
        switch self {
        case .weekly: "Compra semanal"
        case .monthly: "Compra mensual"
        case .hybrid: "Compra híbrida"
        }
    }

    var explanation: String {
        switch self {
        case .weekly: "Útil para productos frescos y para controlar mejor el gasto."
        case .monthly: "Útil para productos duraderos y compras en cantidad."
        case .hybrid: "Una compra principal al mes y reposiciones semanales de frescos."
        }
    }

    static var recommended: GroceryMode { .hybrid }

    /// Default share of the monthly grocery budget spent in the main run.
    var defaultMainShare: Double {
        switch self {
        case .weekly: 0
        case .monthly: 1
        case .hybrid: 0.55
        }
    }
}

/// The grocery budget split into a main purchase and weekly top-ups.
struct GroceryPlan: Equatable, Sendable {
    let mode: GroceryMode
    let monthly: Money
    let mainPurchase: Money
    let weeklyRestock: Money
    let restockWeeks: Int

    /// The split must add back up to the monthly grocery budget.
    var reconstructedMonthly: Money {
        mainPurchase + weeklyRestock * Money(restockWeeks)
    }
}
