import Foundation

/// How often the money arrives.
enum PaydayFrequency: String, CaseIterable, Codable, Identifiable, Sendable {
    /// Once a month, on a day of the month.
    case monthly
    /// Twice a month, on two days of the month. What "quincenal" usually means here:
    /// the 15th and the end of the month.
    case semimonthly
    /// Every two weeks, counted from a payday the user names. Not the same as twice a
    /// month: it drifts, and some months carry three.
    case biweekly
    /// Every week, on a weekday.
    case weekly

    var id: String { rawValue }

    var label: String {
        switch self {
        case .monthly: "Mensual"
        case .semimonthly: "Quincenal"
        case .biweekly: "Cada dos semanas"
        case .weekly: "Semanal"
        }
    }

    var detail: String {
        switch self {
        case .monthly: "Una vez al mes"
        case .semimonthly: "Dos veces al mes, por ejemplo el 15 y el 30"
        case .biweekly: "Cada 14 días, así que algunos meses caen tres"
        case .weekly: "Una vez por semana"
        }
    }

    /// Whether the day is a day of the month or a day of the week.
    var usesDayOfMonth: Bool { self != .weekly }

    /// Whether a second day of the month has to be asked for.
    var needsSecondDay: Bool { self == .semimonthly }

    /// Whether a starting date is needed, because the schedule cannot be derived from
    /// the calendar alone.
    var needsAnchor: Bool { self == .biweekly }
}

/// When the user gets paid, which is when the app asks them to move money.
///
/// The plan says what to pay every month. It is useless on the wrong day: nobody pays a
/// card the morning before their salary lands. This is the app's one chance to be in
/// the right place at the right time.
struct PaydaySchedule: Equatable, Codable, Sendable {
    var frequency: PaydayFrequency
    /// Day of the month, or the weekday for a weekly schedule where 1 is Sunday.
    var primaryDay: Int
    /// The second day of the month, for a semimonthly schedule.
    var secondaryDay: Int?
    /// A payday the user names, for the schedules that repeat by counting days.
    var anchor: Date?

    /// Reads as "the last day of the month" wherever a day of 31 would not exist.
    static let lastDayOfMonth = 31

    static let monthlyDefault = PaydaySchedule(frequency: .monthly, primaryDay: 30, secondaryDay: nil, anchor: nil)
    static let semimonthlyDefault = PaydaySchedule(frequency: .semimonthly, primaryDay: 15, secondaryDay: lastDayOfMonth, anchor: nil)
    static let weeklyDefault = PaydaySchedule(frequency: .weekly, primaryDay: 6, secondaryDay: nil, anchor: nil)

    static func `default`(for frequency: PaydayFrequency, anchor: Date) -> PaydaySchedule {
        switch frequency {
        case .monthly: monthlyDefault
        case .semimonthly: semimonthlyDefault
        case .weekly: weeklyDefault
        case .biweekly: PaydaySchedule(frequency: .biweekly, primaryDay: 1, secondaryDay: nil, anchor: anchor)
        }
    }

    /// Both days of the month this schedule pays on, sorted.
    var daysOfMonth: [Int] {
        guard frequency.usesDayOfMonth else { return [] }
        return ([primaryDay] + (frequency.needsSecondDay ? [secondaryDay].compactMap { $0 } : [])).sorted()
    }

    /// How many paydays a month holds, for anywhere that has to divide by them.
    var paydaysPerMonth: Double {
        switch frequency {
        case .monthly: 1
        case .semimonthly: 2
        case .biweekly: 26.0 / 12.0
        case .weekly: 52.0 / 12.0
        }
    }
}
