import Foundation
import SwiftData

/// Storage for utilities and their monthly readings.
@MainActor
protocol UtilityRepositing {
    func all() -> [UtilityEntity]
    func active() -> [UtilityEntity]
    /// The reading for a month, created with the current reserve if absent.
    func reading(for utility: UtilityEntity, monthOf date: Date) -> UtilityReadingEntity
    /// Records the real bill and what should happen to any leftover.
    func settle(
        _ utility: UtilityEntity,
        monthOf date: Date,
        actual: Money?,
        paidBySomeoneElse: Bool,
        surplusDestination: SurplusDestination?
    ) -> UtilityReadingEntity
    func add(_ utility: UtilityEntity)
    func delete(_ utility: UtilityEntity)
    func save()
}

@MainActor
struct UtilityRepository: UtilityRepositing {
    private let context: ModelContext
    private let monthKeys: MonthKeyFormatter

    init(context: ModelContext, monthKeys: MonthKeyFormatter = MonthKeyFormatter()) {
        self.context = context
        self.monthKeys = monthKeys
    }

    func all() -> [UtilityEntity] {
        let descriptor = FetchDescriptor<UtilityEntity>(sortBy: [SortDescriptor(\.order), SortDescriptor(\.name)])
        return (try? context.fetch(descriptor)) ?? []
    }

    func active() -> [UtilityEntity] {
        all().filter(\.isActive)
    }

    func reading(for utility: UtilityEntity, monthOf date: Date) -> UtilityReadingEntity {
        let key = monthKeys.key(for: date)
        if let existing = utility.reading(forMonth: key) { return existing }

        let reading = UtilityReadingEntity(monthKey: key, reservedAmount: utility.estimatedAmount)
        reading.utility = utility
        context.insert(reading)
        save()
        return reading
    }

    func settle(
        _ utility: UtilityEntity,
        monthOf date: Date,
        actual: Money?,
        paidBySomeoneElse: Bool,
        surplusDestination: SurplusDestination?
    ) -> UtilityReadingEntity {
        let reading = reading(for: utility, monthOf: date)
        reading.actualAmount = actual
        reading.paidBySomeoneElse = paidBySomeoneElse
        // Only a positive difference is a surplus to place; a bill above the
        // reserve is an overrun and has nowhere to go.
        reading.surplusDestination = reading.difference > 0 ? surplusDestination : nil
        reading.recordedAt = date
        save()
        return reading
    }

    func add(_ utility: UtilityEntity) {
        context.insert(utility)
        save()
    }

    func delete(_ utility: UtilityEntity) {
        context.delete(utility)
        save()
    }

    func save() {
        try? context.save()
    }
}
