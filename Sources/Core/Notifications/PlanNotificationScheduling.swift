import Foundation

/// Schedules the app's reminders.
///
/// Behind a protocol so previews and tests never touch the notification centre,
/// and so the rules about *what* is worth notifying stay separate from *how*
/// notifications are delivered.
protocol PlanNotificationScheduling: Sendable {
    func requestAuthorization() async -> Bool
    /// Replaces all pending reminders with the ones this plan implies.
    ///
    /// - Parameter payday: when the money arrives and whether this period's abonos are
    ///   already registered. Nil when the user has no payday set, which simply means no
    ///   payday reminders.
    func reschedule(
        for plan: FinancialPlan,
        snapshot: FinancialSnapshot,
        reminder: DailyReminder,
        payday: PaydayReminder?
    ) async
    func cancelAll() async
}

/// When the nightly "did you log today's spending?" reminder fires.
struct DailyReminder: Equatable, Sendable {
    var hour: Int
    var minute: Int
    var isEnabled: Bool

    static var `default`: DailyReminder { DailyReminder(hour: 21, minute: 0, isEnabled: true) }
}

/// Used in previews and tests.
struct NoopNotificationScheduler: PlanNotificationScheduling {
    func requestAuthorization() async -> Bool { false }
    func reschedule(
        for plan: FinancialPlan,
        snapshot: FinancialSnapshot,
        reminder: DailyReminder,
        payday: PaydayReminder?
    ) async {}
    func cancelAll() async {}
}
