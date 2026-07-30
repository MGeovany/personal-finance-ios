import Foundation

/// The categories the app starts with.
///
/// Each one declares its own flexibility, which is what tells the engine how hard
/// it may be cut: groceries and transport are essential and barely move, dining
/// out and entertainment absorb most of an aggressive plan.
enum DefaultCategories {
    static func make() -> [CategoryEntity] {
        definitions.enumerated().map { index, definition in
            CategoryEntity(
                key: definition.key,
                name: definition.name,
                icon: definition.icon,
                baseline: 0,
                flexibility: definition.flexibility,
                order: index
            )
        }
    }

    private struct Definition {
        let key: String
        let name: String
        let icon: String
        let flexibility: CategoryFlexibility
    }

    private static let definitions: [Definition] = [
        Definition(key: CategoryKeys.groceries, name: "Supermercado", icon: "cart", flexibility: .essential),
        Definition(key: CategoryKeys.transport, name: "Uber y transporte", icon: "car", flexibility: .essential),
        Definition(key: CategoryKeys.restaurants, name: "Restaurantes", icon: "fork.knife", flexibility: .discretionary),
        Definition(key: CategoryKeys.delivery, name: "Delivery", icon: "bag", flexibility: .discretionary),
        Definition(key: CategoryKeys.outings, name: "Salidas", icon: "party.popper", flexibility: .discretionary),
        Definition(key: CategoryKeys.entertainment, name: "Entretenimiento", icon: "gamecontroller", flexibility: .discretionary),
        Definition(key: CategoryKeys.pharmacy, name: "Farmacia", icon: "cross.case", flexibility: .essential),
        Definition(key: CategoryKeys.hygiene, name: "Higiene", icon: "drop", flexibility: .essential),
        Definition(key: CategoryKeys.health, name: "Salud", icon: "heart", flexibility: .essential),
        Definition(key: CategoryKeys.clothing, name: "Ropa", icon: "tshirt", flexibility: .discretionary),
        Definition(key: CategoryKeys.technology, name: "Tecnología", icon: "laptopcomputer", flexibility: .discretionary),
        Definition(key: CategoryKeys.travel, name: "Viajes", icon: "airplane", flexibility: .discretionary),
        Definition(key: CategoryKeys.education, name: "Educación", icon: "book", flexibility: .discretionary),
        Definition(key: CategoryKeys.gifts, name: "Regalos", icon: "gift", flexibility: .discretionary),
        Definition(key: CategoryKeys.unexpected, name: "Imprevistos", icon: "exclamationmark.triangle", flexibility: .buffer),
        Definition(key: CategoryKeys.other, name: "Otros", icon: "ellipsis.circle", flexibility: .discretionary),
        // Utilities and subscriptions have their own screens and exact amounts.
        // They exist as categories only so an expense can be filed against them.
        Definition(key: CategoryKeys.utilities, name: "Servicios públicos", icon: "bolt", flexibility: .reserved),
        Definition(key: CategoryKeys.subscriptions, name: "Suscripciones", icon: "repeat", flexibility: .reserved),
    ]
}
