import Foundation

/// When the daily nudge arrives, named as a moment in the day rather than an hour.
///
/// People know they look at their phone over breakfast, at lunch, or in bed. They do
/// not know whether they want a notification at 20:00 or 21:00, and asking them to
/// set a clock turns a one-tap answer into a chore.
///
/// The moment also decides what the notification can honestly ask: at breakfast the
/// spending it is asking about happened yesterday.
enum ReminderMoment: String, CaseIterable, Identifiable, Codable, Sendable {
    case morning
    case midday
    case beforeBed

    var id: String { rawValue }

    var hour: Int {
        switch self {
        case .morning: 8
        case .midday: 13
        case .beforeBed: 21
        }
    }

    var label: String {
        switch self {
        case .morning: "En la mañana"
        case .midday: "En el almuerzo"
        case .beforeBed: "Antes de dormir"
        }
    }

    /// The hour spelled out, so the choice is informative without being editable.
    var detail: String {
        switch self {
        case .morning: "8:00 AM"
        case .midday: "1:00 PM"
        case .beforeBed: "9:00 PM"
        }
    }

    var icon: String {
        switch self {
        case .morning: "sunrise"
        case .midday: "sun.max"
        case .beforeBed: "moon.stars"
        }
    }

    static var `default`: ReminderMoment { .beforeBed }

    /// The moment an hour belongs to, so a stored hour still maps back onto a choice.
    static func containing(hour: Int) -> ReminderMoment {
        allCases.min { abs($0.hour - hour) < abs($1.hour - hour) } ?? .default
    }
}
