import Foundation
import SwiftData

/// A spending category with its declared budget.
///
/// `flexibility` lives on the row rather than in a lookup table so that
/// user-created categories choose their own behaviour, and the engine never has
/// to know which categories shipped with the app.
@Model
final class CategoryEntity {
    var uuid: UUID
    /// Stable key: the built-in ones match `CategoryKeys`, custom ones get a UUID string.
    var key: String
    var name: String
    var icon: String
    /// What the user says this costs them monthly.
    var baseline: Money
    var flexibilityRaw: String
    /// A budget the user pinned by hand, which plans must honour exactly.
    var budgetOverride: Money?
    var isHidden: Bool
    var order: Int
    var createdAt: Date

    init(
        uuid: UUID = UUID(),
        key: String,
        name: String,
        icon: String,
        baseline: Money = 0,
        flexibility: CategoryFlexibility = .discretionary,
        budgetOverride: Money? = nil,
        isHidden: Bool = false,
        order: Int = 0,
        createdAt: Date = Date()
    ) {
        self.uuid = uuid
        self.key = key
        self.name = name
        self.icon = icon
        self.baseline = baseline
        self.flexibilityRaw = flexibility.rawValue
        self.budgetOverride = budgetOverride
        self.isHidden = isHidden
        self.order = order
        self.createdAt = createdAt
    }
}

extension CategoryEntity {
    var flexibility: CategoryFlexibility {
        get { CategoryFlexibility(rawValue: flexibilityRaw) ?? .discretionary }
        set { flexibilityRaw = newValue.rawValue }
    }

    /// Built-in categories cannot be deleted, only hidden, because plans and
    /// history reference their keys.
    var isBuiltIn: Bool { UUID(uuidString: key) == nil }
}
