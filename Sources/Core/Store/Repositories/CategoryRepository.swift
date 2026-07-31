import Foundation
import SwiftData

/// Storage for spending categories.
@MainActor
protocol CategoryRepositing {
    func all() -> [CategoryEntity]
    func visible() -> [CategoryEntity]
    func category(forKey key: String) -> CategoryEntity?
    func add(_ category: CategoryEntity)
    func delete(_ category: CategoryEntity)
    /// Rewrites `order` to match the given sequence.
    func reorder(_ categories: [CategoryEntity])
    /// Creates the default set the first time the app runs.
    func seedDefaultsIfNeeded()
    func save()
}

@MainActor
struct CategoryRepository: CategoryRepositing {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func all() -> [CategoryEntity] {
        let descriptor = FetchDescriptor<CategoryEntity>(sortBy: [SortDescriptor(\.order)])
        return (try? context.fetch(descriptor)) ?? []
    }

    func visible() -> [CategoryEntity] {
        all().filter { !$0.isHidden }
    }

    func category(forKey key: String) -> CategoryEntity? {
        all().first { $0.key == key }
    }

    func add(_ category: CategoryEntity) {
        context.insert(category)
        save()
    }

    func delete(_ category: CategoryEntity) {
        // Built-in categories are referenced by stored expenses, so they are
        // hidden rather than removed: history must stay readable.
        if category.isBuiltIn {
            category.isHidden = true
        } else {
            context.delete(category)
        }
        save()
    }

    func reorder(_ categories: [CategoryEntity]) {
        for (index, category) in categories.enumerated() {
            category.order = index
        }
        save()
    }

    func seedDefaultsIfNeeded() {
        let existing = all()
        if existing.isEmpty {
            for category in DefaultCategories.make() {
                context.insert(category)
            }
            save()
            return
        }

        // Keep built-in names current, hide retired buckets, add any new ones.
        let definitions = Dictionary(
            uniqueKeysWithValues: DefaultCategories.definitions.map { ($0.key, $0) }
        )
        let existingKeys = Set(existing.map(\.key))

        for category in existing {
            if let definition = definitions[category.key] {
                if category.name != definition.name { category.name = definition.name }
                if category.icon != definition.icon { category.icon = definition.icon }
                category.isHidden = definition.isHidden
                category.order = definitionOrder(definition.key)
            } else if category.isBuiltIn {
                // Retired defaults (Ropa, Farmacia, …) stay for history but leave the picker.
                category.isHidden = true
            }
        }

        for definition in DefaultCategories.definitions where !existingKeys.contains(definition.key) {
            context.insert(
                CategoryEntity(
                    key: definition.key,
                    name: definition.name,
                    icon: definition.icon,
                    baseline: 0,
                    flexibility: definition.flexibility,
                    isHidden: definition.isHidden,
                    order: definitionOrder(definition.key)
                )
            )
        }
        save()
    }

    private func definitionOrder(_ key: String) -> Int {
        DefaultCategories.definitions.firstIndex { $0.key == key } ?? 0
    }

    func save() {
        try? context.save()
    }
}
