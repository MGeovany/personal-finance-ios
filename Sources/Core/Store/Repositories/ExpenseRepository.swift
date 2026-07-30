import Foundation
import SwiftData

/// Storage and the period queries the budget screens need.
@MainActor
protocol ExpenseRepositing {
    func all() -> [ExpenseEntity]
    func expenses(from start: Date, to end: Date) -> [ExpenseEntity]
    func expenses(inMonthOf date: Date) -> [ExpenseEntity]
    func expenses(on day: Date) -> [ExpenseEntity]
    func needingReview() -> [ExpenseEntity]
    /// Total reserved against future card statements: money that exists but is spoken for.
    func totalReservedForCards() -> Money
    func add(_ expense: ExpenseEntity)
    func delete(_ expense: ExpenseEntity)
    func save()
}

@MainActor
struct ExpenseRepository: ExpenseRepositing {
    private let context: ModelContext
    private let calendar: Calendar

    init(context: ModelContext, calendar: Calendar = .current) {
        self.context = context
        self.calendar = calendar
    }

    func all() -> [ExpenseEntity] {
        let descriptor = FetchDescriptor<ExpenseEntity>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        return (try? context.fetch(descriptor)) ?? []
    }

    func expenses(from start: Date, to end: Date) -> [ExpenseEntity] {
        let descriptor = FetchDescriptor<ExpenseEntity>(
            predicate: #Predicate { $0.date >= start && $0.date < end },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func expenses(inMonthOf date: Date) -> [ExpenseEntity] {
        let start = calendar.startOfMonth(for: date)
        let end = calendar.addingMonths(1, to: start)
        return expenses(from: start, to: end)
    }

    func expenses(on day: Date) -> [ExpenseEntity] {
        let start = calendar.startOfDay(for: day)
        return expenses(from: start, to: calendar.addingDays(1, to: start))
    }

    func needingReview() -> [ExpenseEntity] {
        let descriptor = FetchDescriptor<ExpenseEntity>(
            predicate: #Predicate { $0.needsReview },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func totalReservedForCards() -> Money {
        let reserved = ExpenseBacking.reserved.rawValue
        let descriptor = FetchDescriptor<ExpenseEntity>(predicate: #Predicate { $0.backingRaw == reserved })
        let matches = (try? context.fetch(descriptor)) ?? []
        return matches.reduce(Money.zero) { $0 + $1.amount }
    }

    func add(_ expense: ExpenseEntity) {
        context.insert(expense)
        save()
    }

    func delete(_ expense: ExpenseEntity) {
        context.delete(expense)
        save()
    }

    func save() {
        try? context.save()
    }
}
