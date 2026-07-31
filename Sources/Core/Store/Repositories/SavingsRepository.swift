import Foundation
import SwiftData

/// Money moving into savings: the balance and the dated record of the move, together.
///
/// Both halves live behind one call on purpose. When they were separate, every caller had
/// to remember to write the ledger entry after changing the balance, and the one that
/// forgot is exactly how a saver ends up being told they have done nothing.
@MainActor
protocol SavingsRepositing {
    /// Adds to the cushion and records the move.
    func contributeToEmergencyFund(_ amount: Money, on date: Date, note: String)
    /// Adds to a goal, records the move, and marks the goal complete if it fills up.
    func contribute(_ amount: Money, to goal: GoalEntity, on date: Date, note: String)
    /// The most recent move into savings of any kind.
    func lastContribution() -> Date?
    func contributions(from start: Date, to end: Date) -> [SavingsContributionEntity]
}

@MainActor
struct SavingsRepository: SavingsRepositing {
    private let context: ModelContext
    private let profiles: ProfileProviding

    init(context: ModelContext, profiles: ProfileProviding) {
        self.context = context
        self.profiles = profiles
    }

    func contributeToEmergencyFund(_ amount: Money, on date: Date, note: String) {
        guard amount > 0 else { return }

        let profile = profiles.profile()
        profile.emergencyFund += amount
        record(amount, destination: .emergencyFund, goalID: nil, on: date, note: note)
    }

    func contribute(_ amount: Money, to goal: GoalEntity, on date: Date, note: String) {
        guard amount > 0 else { return }

        goal.savedAmount += amount
        if goal.isComplete, goal.completedAt == nil {
            goal.completedAt = date
        }
        record(amount, destination: .goal, goalID: goal.uuid, on: date, note: note)
    }

    func lastContribution() -> Date? {
        var descriptor = FetchDescriptor<SavingsContributionEntity>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return (try? context.fetch(descriptor))?.first?.date
    }

    func contributions(from start: Date, to end: Date) -> [SavingsContributionEntity] {
        let descriptor = FetchDescriptor<SavingsContributionEntity>(
            predicate: #Predicate { $0.date >= start && $0.date < end },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    private func record(
        _ amount: Money,
        destination: SavingsDestination,
        goalID: UUID?,
        on date: Date,
        note: String
    ) {
        context.insert(
            SavingsContributionEntity(
                amount: amount,
                date: date,
                destination: destination,
                goalID: goalID,
                note: note
            )
        )
        try? context.save()
    }
}
