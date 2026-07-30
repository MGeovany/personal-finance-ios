import Foundation
import SwiftData

/// Storage for secondary goals.
@MainActor
protocol GoalRepositing {
    func all() -> [GoalEntity]
    func active() -> [GoalEntity]
    func goal(withID id: UUID) -> GoalEntity?
    func add(_ goal: GoalEntity)
    func delete(_ goal: GoalEntity)
    /// Moves money into a goal, marking it complete when it fills up.
    func contribute(_ amount: Money, to goal: GoalEntity, on date: Date)
    func save()
}

@MainActor
struct GoalRepository: GoalRepositing {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func all() -> [GoalEntity] {
        let descriptor = FetchDescriptor<GoalEntity>(sortBy: [SortDescriptor(\.priority), SortDescriptor(\.createdAt)])
        return (try? context.fetch(descriptor)) ?? []
    }

    func active() -> [GoalEntity] {
        all().filter { $0.completedAt == nil }
    }

    func goal(withID id: UUID) -> GoalEntity? {
        all().first { $0.uuid == id }
    }

    func add(_ goal: GoalEntity) {
        context.insert(goal)
        save()
    }

    func delete(_ goal: GoalEntity) {
        context.delete(goal)
        save()
    }

    func contribute(_ amount: Money, to goal: GoalEntity, on date: Date) {
        goal.savedAmount += amount
        if goal.isComplete, goal.completedAt == nil {
            goal.completedAt = date
        }
        save()
    }

    func save() {
        try? context.save()
    }
}
