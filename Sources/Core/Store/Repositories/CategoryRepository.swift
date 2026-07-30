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
        guard all().isEmpty else { return }
        for category in DefaultCategories.make() {
            context.insert(category)
        }
        save()
    }

    func save() {
        try? context.save()
    }
}
