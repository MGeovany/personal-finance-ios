import Foundation

/// Keys for the categories the app ships with. Features that need to reason
/// about a specific category (groceries has its own purchase modes, the buffer
/// absorbs overspending) look it up by these instead of by localized name.
///
/// User-created categories get a generated key and are never referenced here.
enum CategoryKeys {
    static let groceries = "groceries"
    static let delivery = "delivery"
    static let online = "online"
    static let transport = "transport"
    static let outings = "outings"
    static let unexpected = "unexpected"
    static let other = "other"
    static let utilities = "utilities"
    static let subscriptions = "subscriptions"

    // Legacy keys: still recognised in stored expenses, but no longer offered.
    static let restaurants = "restaurants"
    static let pharmacy = "pharmacy"
    static let hygiene = "hygiene"
    static let clothing = "clothing"
    static let technology = "technology"
    static let entertainment = "entertainment"
    static let travel = "travel"
    static let education = "education"
    static let health = "health"
    static let gifts = "gifts"

    /// Categories the onboarding asks about explicitly.
    static let onboardingEssentials = [groceries, transport, outings]

    /// None of the short everyday list is a monthly bill by default.
    static func allowsRecurringExpense(_ key: String) -> Bool {
        key == subscriptions || key == utilities
    }
}
