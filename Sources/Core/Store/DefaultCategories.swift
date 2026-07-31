import Foundation

/// The categories the app starts with.
///
/// Kept short on purpose: everyday spending in a few buckets people recognise.
/// Older built-in keys may still exist in storage for history; those are hidden.
enum DefaultCategories {
    static func make() -> [CategoryEntity] {
        definitions.enumerated().map { index, definition in
            CategoryEntity(
                key: definition.key,
                name: definition.name,
                icon: definition.icon,
                baseline: 0,
                flexibility: definition.flexibility,
                isHidden: definition.isHidden,
                order: index
            )
        }
    }

    struct Definition {
        let key: String
        let name: String
        let icon: String
        let flexibility: CategoryFlexibility
        var isHidden: Bool = false
    }

    /// Visible spending buckets. Reserved utilities/subscriptions stay seeded but
    /// hidden; they have their own screens.
    static let definitions: [Definition] = [
        Definition(key: CategoryKeys.groceries, name: "Super", icon: "cart", flexibility: .essential),
        Definition(key: CategoryKeys.delivery, name: "Pedidos Ya", icon: "bag", flexibility: .discretionary),
        Definition(key: CategoryKeys.online, name: "Compras en línea", icon: "cart.badge.plus", flexibility: .discretionary),
        Definition(key: CategoryKeys.transport, name: "Uber", icon: "car", flexibility: .essential),
        Definition(key: CategoryKeys.outings, name: "Salida", icon: "party.popper", flexibility: .discretionary),
        Definition(key: CategoryKeys.unexpected, name: "Imprevisto", icon: "exclamationmark.triangle", flexibility: .buffer),
        Definition(key: CategoryKeys.other, name: "Otros", icon: "ellipsis.circle", flexibility: .discretionary),
        Definition(key: CategoryKeys.utilities, name: "Servicios públicos", icon: "bolt", flexibility: .reserved, isHidden: true),
        Definition(key: CategoryKeys.subscriptions, name: "Suscripciones", icon: "repeat", flexibility: .reserved, isHidden: true),
    ]

    static var visibleKeys: Set<String> {
        Set(definitions.filter { !$0.isHidden }.map(\.key))
    }
}
