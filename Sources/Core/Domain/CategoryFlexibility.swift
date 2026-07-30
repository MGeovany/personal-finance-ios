import Foundation

/// How much a category can be squeezed when the user picks a faster plan.
///
/// This is what keeps the engine honest: no plan may recommend a grocery or
/// transport budget that is impossible to live on, while dining out and
/// entertainment can be cut deeply.
enum CategoryFlexibility: String, CaseIterable, Codable, Sendable {
    /// Groceries, transport, health, hygiene. Needed to function.
    case essential
    /// Restaurants, delivery, clothes, entertainment, outings. Nice to have.
    case discretionary
    /// Money set aside for the unexpected. Sized by the plan, not by history.
    case buffer
    /// Utilities and subscriptions: real amounts with a due date, reserved
    /// separately and never mixed into the flexible budget.
    case reserved

    /// The deepest cut a plan may apply, as a fraction of what the user declared.
    /// An aggressive plan can take dining out to a quarter, but never take
    /// groceries below three quarters.
    var floorFactor: Double {
        switch self {
        case .essential: 0.75
        case .discretionary: 0.25
        case .buffer: 0.20
        case .reserved: 1.0
        }
    }

    /// Whether the category is funded out of the monthly flexible budget.
    var participatesInFlexibleBudget: Bool { self != .reserved }

    var label: String {
        switch self {
        case .essential: "Esencial"
        case .discretionary: "Flexible"
        case .buffer: "Imprevistos"
        case .reserved: "Reservado"
        }
    }
}
