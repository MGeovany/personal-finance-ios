import Foundation

/// Builds the `yyyy-MM` and `yyyy-Www` keys used to tag a month or a week.
///
/// Stored records key off strings rather than dates so "the reading for July" is
/// a lookup instead of a range query, and so equality never depends on a time of
/// day or a time zone drifting.
struct MonthKeyFormatter: Sendable {
    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    /// `2026-07`
    func key(for date: Date) -> String {
        let parts = calendar.dateComponents([.year, .month], from: date)
        return String(format: "%04d-%02d", parts.year ?? 0, parts.month ?? 0)
    }

    /// `2026-W31`
    func weekKey(for date: Date) -> String {
        let parts = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return String(format: "%04d-W%02d", parts.yearForWeekOfYear ?? 0, parts.weekOfYear ?? 0)
    }

    /// `2026-07-30`
    func dayKey(for date: Date) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    func reviewKey(_ kind: ReviewKind, for date: Date) -> String {
        switch kind {
        case .daily: "daily-\(dayKey(for: date))"
        case .weekly: "weekly-\(weekKey(for: date))"
        case .monthly: "monthly-\(key(for: date))"
        }
    }
}
