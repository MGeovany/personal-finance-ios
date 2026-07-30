import Foundation
import SwiftData

/// Storage for committed expenses that are neither utilities nor subscriptions.
@MainActor
protocol FixedExpenseRepositing {
    func all() -> [FixedExpenseEntity]
    func active() -> [FixedExpenseEntity]
    func add(_ expense: FixedExpenseEntity)
    func delete(_ expense: FixedExpenseEntity)
    func save()
}

@MainActor
struct FixedExpenseRepository: FixedExpenseRepositing {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func all() -> [FixedExpenseEntity] {
        let descriptor = FetchDescriptor<FixedExpenseEntity>(sortBy: [SortDescriptor(\.createdAt)])
        return (try? context.fetch(descriptor)) ?? []
    }

    func active() -> [FixedExpenseEntity] {
        all().filter(\.isActive)
    }

    func add(_ expense: FixedExpenseEntity) {
        context.insert(expense)
        save()
    }

    func delete(_ expense: FixedExpenseEntity) {
        context.delete(expense)
        save()
    }

    func save() {
        try? context.save()
    }
}
