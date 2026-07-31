import Foundation

/// Where the user stands relative to their last payday.
///
/// The whole point of knowing the payday is this: the app can tell the difference
/// between "nothing to do today" and "the money landed three days ago and none of it
/// has moved". Those are the two states that decide what the dashboard leads with.
enum PaydayStatus: Equatable, Sendable {
    /// No schedule set, so the app has nothing to be right about.
    case notScheduled
    /// Today. The one day the plan's instructions are worth interrupting for.
    case today(daysSinceLast: Int)
    /// The payday has passed and nothing has been registered since. `days` is how long,
    /// which is what turns a reminder into an unmissable one.
    case pending(since: Date, days: Int)
    /// Something was registered after the last payday. Done for this period.
    case registered(on: Date)
    /// Between paydays with the last one settled.
    case waiting(next: Date?)

    /// After this many days with nothing registered, the app stops being polite about it
    /// and starts saying it every day.
    static let insistAfterDays = 3

    var isPayday: Bool {
        if case .today = self { return true }
        return false
    }

    /// Whether the dashboard should lead with this rather than tuck it away.
    var deservesTheTopOfTheScreen: Bool {
        switch self {
        case .today: true
        case .pending(_, let days): days >= 1
        case .notScheduled, .registered, .waiting: false
        }
    }

    /// Whether it has waited long enough to be repeated daily.
    var isInsistent: Bool {
        guard case .pending(_, let days) = self else { return false }
        return days >= Self.insistAfterDays
    }

    var daysWaiting: Int {
        switch self {
        case .pending(_, let days): days
        default: 0
        }
    }
}
