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
    }

    let id: String
    let title: String
    let body: String
    let trigger: Trigger
}
