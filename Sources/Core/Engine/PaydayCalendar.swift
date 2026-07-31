import Foundation

/// Answers when the paydays are.
///
/// All the calendar arithmetic a payday schedule implies, in one place, because "the
/// 31st" in February and "every two weeks" across a month boundary are exactly the
/// kind of thing that gets quietly wrong when it is written twice.
struct PaydayCalendar: Sendable {
    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func isPayday(_ date: Date, schedule: PaydaySchedule) -> Bool {
        switch schedule.frequency {
        case .monthly, .semimonthly:
            return schedule.daysOfMonth.contains { matchesDayOfMonth($0, on: date) }
        case .weekly:
            return calendar.component(.weekday, from: date) == schedule.primaryDay
        case .biweekly:
            guard let anchor = schedule.anchor else { return false }
            let days = calendar.days(from: anchor, to: date)
            return days % 14 == 0
        }
    }

    /// The most recent payday on or before `date`. Nil only when a biweekly schedule has
    /// no anchor to count from.
    func lastPayday(onOrBefore date: Date, schedule: PaydaySchedule) -> Date? {
        // Ninety days back covers even a monthly schedule landing on a day the last two
        // months did not have.
        candidates(around: date, schedule: schedule, backDays: 95, forwardDays: 0)
            .last { calendar.startOfDay(for: $0) <= calendar.startOfDay(for: date) }
    }

    func nextPayday(after date: Date, schedule: PaydaySchedule) -> Date? {
        candidates(around: date, schedule: schedule, backDays: 0, forwardDays: 95)
            .first { calendar.startOfDay(for: $0) > calendar.startOfDay(for: date) }
    }

    /// Whole days since the last payday, for deciding when a missing payment has waited
    /// long enough to be worth mentioning.
    func daysSinceLastPayday(_ date: Date, schedule: PaydaySchedule) -> Int? {
        guard let last = lastPayday(onOrBefore: date, schedule: schedule) else { return nil }
        return calendar.days(from: last, to: date)
    }

    /// The next few paydays, for scheduling notifications that cannot repeat on their own.
    func upcomingPaydays(after date: Date, schedule: PaydaySchedule, limit: Int) -> [Date] {
        Array(
            candidates(around: date, schedule: schedule, backDays: 0, forwardDays: 120)
                .filter { calendar.startOfDay(for: $0) > calendar.startOfDay(for: date) }
                .prefix(limit)
        )
    }

    // MARK: - Enumerating

    /// Every payday in a window around a date, in order.
    ///
    /// Walking days is the honest way to do this: a day-of-month schedule has to be
    /// clamped to the length of each month, and a counted schedule has to cross month
    /// boundaries. Both fall out of walking rather than out of arithmetic on components.
    private func candidates(
        around date: Date,
        schedule: PaydaySchedule,
        backDays: Int,
        forwardDays: Int
    ) -> [Date] {
        let start = calendar.addingDays(-backDays, to: calendar.startOfDay(for: date))
        let total = backDays + forwardDays

        return (0...total).compactMap { offset in
            let day = calendar.addingDays(offset, to: start)
            return isPayday(day, schedule: schedule) ? day : nil
        }
    }

    /// True when `day` is the schedule's day in the month `date` falls in, treating any
    /// day past the end of the month as the last day of it. A schedule that pays on the
    /// 31st pays on the 28th of February, not never.
    private func matchesDayOfMonth(_ day: Int, on date: Date) -> Bool {
        let dayInMonth = calendar.component(.day, from: date)
        guard let range = calendar.range(of: .day, in: .month, for: date) else {
            return dayInMonth == day
        }
        let lastDay = range.count
        return dayInMonth == min(day, lastDay)
    }
}
