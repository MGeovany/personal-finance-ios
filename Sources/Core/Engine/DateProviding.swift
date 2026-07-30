import Foundation

/// Injectable "now", so projections are deterministic under test instead of
/// depending on the day the suite happens to run.
protocol DateProviding: Sendable {
    var now: Date { get }
    var calendar: Calendar { get }
}

struct SystemDateProvider: DateProviding {
    var now: Date { Date() }
    var calendar: Calendar { Calendar.current }
}

/// Fixed clock for tests and previews.
struct FixedDateProvider: DateProviding {
    let now: Date
    var calendar: Calendar = Calendar(identifier: .gregorian)
}

extension Calendar {
    /// Start of the month containing `date`.
    func startOfMonth(for date: Date) -> Date {
        let parts = dateComponents([.year, .month], from: date)
        return self.date(from: parts) ?? date
    }

    func addingMonths(_ months: Int, to date: Date) -> Date {
        self.date(byAdding: .month, value: months, to: date) ?? date
    }

    func addingDays(_ days: Int, to date: Date) -> Date {
        self.date(byAdding: .day, value: days, to: date) ?? date
    }

    /// Whole days between two dates, ignoring time of day.
    func days(from start: Date, to end: Date) -> Int {
        let a = startOfDay(for: start)
        let b = startOfDay(for: end)
        return dateComponents([.day], from: a, to: b).day ?? 0
    }

    func daysRemainingInMonth(from date: Date) -> Int {
        guard let range = range(of: .day, in: .month, for: date) else { return 30 }
        let today = component(.day, from: date)
        return max(1, range.count - today + 1)
    }
}
