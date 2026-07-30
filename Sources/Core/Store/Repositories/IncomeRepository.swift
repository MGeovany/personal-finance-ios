import Foundation
import SwiftData

/// Storage for income streams beyond the main salary.
@MainActor
protocol IncomeRepositing {
    func all() -> [IncomeEntity]
    func active() -> [IncomeEntity]
    func add(_ income: IncomeEntity)
    func delete(_ income: IncomeEntity)
    func save()
}

@MainActor
struct IncomeRepository: IncomeRepositing {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func all() -> [IncomeEntity] {
        let descriptor = FetchDescriptor<IncomeEntity>(sortBy: [SortDescriptor(\.createdAt)])
        return (try? context.fetch(descriptor)) ?? []
    }

    func active() -> [IncomeEntity] {
        all().filter(\.isActive)
    }

    func add(_ income: IncomeEntity) {
        context.insert(income)
        save()
    }

    func delete(_ income: IncomeEntity) {
        context.delete(income)
        save()
    }

    func save() {
        try? context.save()
    }
}
