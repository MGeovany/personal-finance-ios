import Foundation

/// A reminder waiting to be scheduled: what it says and when it fires.
///
/// A value type, so what the app *decides* to notify can be unit-tested without
/// asking the system for permission to notify anything.
struct PlannedNotification: Identifiable, Equatable, Sendable {
    enum Trigger: Equatable, Sendable {
        /// Every day at this time.
        case daily(hour: Int, minute: Int)
        /// Every month on this day, at this time.
        case monthly(day: Int, hour: Int, minute: Int)
        /// Every week on this weekday, at this time. `weekday` is numbered the way
        /// `Calendar` numbers it, with 1 for Sunday.
        case weekly(weekday: Int, hour: Int, minute: Int)
        /// Once, at a specific moment.
        ///
        /// For the reminders that cannot repeat because whether they are still needed
        /// depends on what the user has done since. Those get scheduled a few at a time
        /// and rebuilt whenever the answer changes.
        case once(Date)

        /// Whether the system should keep firing this on the same rule.
        var repeats: Bool {
            if case .once = self { return false }
            return true
        }
    }

    let id: String
    let title: String
    let body: String
    let trigger: Trigger
}
