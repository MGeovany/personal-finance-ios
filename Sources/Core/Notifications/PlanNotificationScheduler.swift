import Foundation
import UserNotifications

/// Delivers what `NotificationContentBuilder` decided, through the system.
///
/// Rescheduling always clears first: the plan is the source of truth, and a
/// reminder for a debt that has been paid off would be worse than no reminder.
struct PlanNotificationScheduler: PlanNotificationScheduling {
    private let content: NotificationContentBuilder
    private let center: UNUserNotificationCenter

    init(content: NotificationContentBuilder = NotificationContentBuilder()) {
        self.content = content
        self.center = .current()
    }

    func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    func reschedule(for plan: FinancialPlan, snapshot: FinancialSnapshot, reminder: DailyReminder) async {
        await cancelAll()
        guard reminder.isEnabled else { return }

        for planned in content.notifications(for: plan, snapshot: snapshot, reminder: reminder) {
            try? await center.add(request(for: planned))
        }
    }

    func cancelAll() async {
        center.removeAllPendingNotificationRequests()
    }

    private func request(for planned: PlannedNotification) -> UNNotificationRequest {
        let body = UNMutableNotificationContent()
        body.title = planned.title
        body.body = planned.body
        body.sound = .default

        return UNNotificationRequest(
            identifier: planned.id,
            content: body,
            trigger: UNCalendarNotificationTrigger(dateMatching: components(for: planned.trigger), repeats: true)
        )
    }

    private func components(for trigger: PlannedNotification.Trigger) -> DateComponents {
        var parts = DateComponents()
        switch trigger {
        case .daily(let hour, let minute):
            parts.hour = hour
            parts.minute = minute
        case .monthly(let day, let hour, let minute):
            parts.day = day
            parts.hour = hour
            parts.minute = minute
        }
        return parts
    }
}
