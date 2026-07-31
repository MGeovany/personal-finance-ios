import Foundation

/// Everything the payday reminders need, as a value.
///
/// Bundled so the scheduler keeps one argument for "when the money arrives" instead of
/// five, and so what those reminders say can be worked out without a database.
struct PaydayReminder: Equatable, Sendable {
    let schedule: PaydaySchedule
    let status: PaydayStatus
    /// What the plan asks the user to send to their cards this month, so the reminder can
    /// name the number rather than saying "haz tus abonos".
    let totalToDebt: Money
    /// What the plan asks them to move into savings, when it asks for anything.
    let toSavings: Money
    let currency: CurrencyCode
    /// The moment the reminders are being built for.
    let now: Date

    /// Hour the payday reminder arrives. Late morning: after the deposit has landed and
    /// while the banking app is still a realistic thing to open.
    static let hour = 10
}
