import Foundation

/// Decides what is worth a notification, and writes it.
///
/// The tone rule: every message is useful and direct, and none of them makes the
/// user feel bad. "¿Ya agregaste tus gastos de hoy?" is a question, not a
/// reprimand. And it says where to look.
struct NotificationContentBuilder: Sendable {
    private let money: MoneyFormatting
    private let dates: PlanDateFormatting
    private let calendar: Calendar

    init(
        money: MoneyFormatting = MoneyFormatter(),
        dates: PlanDateFormatting = PlanDateFormatter(),
        calendar: Calendar = .current
    ) {
        self.money = money
        self.dates = dates
        self.calendar = calendar
    }

    func notifications(
        for plan: FinancialPlan,
        snapshot: FinancialSnapshot,
        reminder: DailyReminder,
        payday: PaydayReminder? = nil
    ) -> [PlannedNotification] {
        guard reminder.isEnabled else { return [] }

        return [dailyReview(reminder)]
            + paydayReminders(payday)
            + paymentDueReminders(snapshot: snapshot, plan: plan, reminder: reminder)
            + statementReminders(snapshot: snapshot, reminder: reminder)
            + subscriptionReminders(snapshot: snapshot, reminder: reminder)
    }

    // MARK: - Payday
    //
    // The one reminder the whole plan depends on. Everything else in this file is
    // information; this one asks for an action on the only day it can be taken.

    private func paydayReminders(_ payday: PaydayReminder?) -> [PlannedNotification] {
        guard let payday else { return [] }
        return paydayArrivals(payday) + missedAbonoNudges(payday)
    }

    /// "Hoy es día de pago". Recurring where the calendar can express the schedule, and
    /// scheduled a few at a time where it cannot.
    private func paydayArrivals(_ payday: PaydayReminder) -> [PlannedNotification] {
        let title = "Hoy es día de pago"
        let body = payday.totalToDebt > 0
            ? "Registra tus abonos: \(format(payday.totalToDebt, payday.currency)) a tus tarjetas."
            : "Registra tus abonos para mantener el plan al día."

        switch payday.schedule.frequency {
        case .monthly, .semimonthly:
            return payday.schedule.daysOfMonth.map { day in
                PlannedNotification(
                    id: "payday-\(day)",
                    title: title,
                    body: body,
                    trigger: .monthly(day: day, hour: PaydayReminder.hour, minute: 0)
                )
            }

        case .weekly:
            return [
                PlannedNotification(
                    id: "payday-weekly",
                    title: title,
                    body: body,
                    trigger: .weekly(weekday: payday.schedule.primaryDay, hour: PaydayReminder.hour, minute: 0)
                )
            ]

        case .biweekly:
            // A fourteen day cycle is not a calendar rule, so the next few are booked
            // individually and topped up every time the app rebuilds its reminders.
            return upcomingBiweeklyPaydays(payday).enumerated().map { index, date in
                PlannedNotification(
                    id: "payday-cycle-\(index)",
                    title: title,
                    body: body,
                    trigger: .once(at(PaydayReminder.hour, on: date))
                )
            }
        }
    }

    /// The daily nudges once a payday has gone by with nothing registered.
    ///
    /// A repeating notification cannot know whether it is still needed, so these are
    /// booked one per day and thrown away the moment an abono is registered. The app
    /// rebuilds its reminders then, and these simply do not come back.
    private func missedAbonoNudges(_ payday: PaydayReminder) -> [PlannedNotification] {
        // Only when nothing at all has moved. Somebody who paid two of three cards is
        // working through it and does not need an alarm every morning about the third.
        guard case .pending(let since, let days, let progress) = payday.status,
              !progress.hasStarted
        else { return [] }

        let startingDay = max(days + 1, PaydayStatus.insistAfterDays)
        let dayCount = 5

        return (0..<dayCount).compactMap { offset in
            let dayNumber = startingDay + offset
            guard let date = calendar.date(byAdding: .day, value: dayNumber, to: since) else { return nil }
            guard date > payday.now else { return nil }

            return PlannedNotification(
                id: "payday-missing-\(dayNumber)",
                title: "Aún no registras ningún abono",
                body: "Han pasado \(dayNumber) días desde tu día de pago. Registra un abono para seguir con el plan.",
                trigger: .once(at(PaydayReminder.hour, on: date))
            )
        }
    }

    private func upcomingBiweeklyPaydays(_ payday: PaydayReminder) -> [Date] {
        PaydayCalendar(calendar: calendar)
            .upcomingPaydays(after: payday.now, schedule: payday.schedule, limit: 4)
    }

    private func at(_ hour: Int, on date: Date) -> Date {
        calendar.date(bySettingHour: hour, minute: 0, second: 0, of: date) ?? date
    }

    // MARK: - The daily nudge

    /// Asks about the spending the chosen moment can actually be asking about. At
    /// breakfast that is yesterday's, at lunch it is the morning's, at night it is
    /// the whole day. A reminder that asks about "hoy" at 8:00 AM answers itself.
    private func dailyReview(_ reminder: DailyReminder) -> PlannedNotification {
        PlannedNotification(
            id: "daily-review",
            title: title(for: ReminderMoment.containing(hour: reminder.hour)),
            body: "Revisa tus transacciones en Wallet y en tus aplicaciones bancarias.",
            trigger: .daily(hour: reminder.hour, minute: reminder.minute)
        )
    }

    private func title(for moment: ReminderMoment) -> String {
        switch moment {
        case .morning: "¿Anotaste lo que gastaste ayer?"
        case .midday: "¿Ya anotaste lo que has gastado hoy?"
        case .beforeBed: "¿Ya agregaste tus gastos de hoy?"
        }
    }

    // MARK: - Dates that cost money if missed

    private func paymentDueReminders(
        snapshot: FinancialSnapshot,
        plan: FinancialPlan,
        reminder: DailyReminder
    ) -> [PlannedNotification] {
        snapshot.activeDebts.compactMap { debt in
            guard let dueDay = debt.dueDay else { return nil }
            let isTarget = debt.id == plan.nextTargetDebtID
            let amount = isTarget ? plan.monthlyDebtPayment : debt.minimumPayment

            return PlannedNotification(
                id: "due-\(debt.id)",
                title: "Pago de \(debt.name)",
                body: isTarget
                    ? "Hoy es la fecha límite. Tu pago recomendado es \(format(amount, snapshot.currency))."
                    : "Hoy es la fecha límite. El pago mínimo es \(format(amount, snapshot.currency)).",
                // Early morning, so there is a whole day left to act on it.
                trigger: .monthly(day: dueDay, hour: 9, minute: 0)
            )
        }
    }

    private func statementReminders(snapshot: FinancialSnapshot, reminder: DailyReminder) -> [PlannedNotification] {
        snapshot.activeDebts.compactMap { debt in
            guard let statementDay = debt.statementDay, debt.kind.isRevolving else { return nil }
            return PlannedNotification(
                id: "statement-\(debt.id)",
                title: "Fecha de corte de \(debt.name)",
                body: "Lo que compres desde hoy entra en el siguiente estado de cuenta.",
                trigger: .monthly(day: statementDay, hour: 9, minute: 0)
            )
        }
    }

    private func subscriptionReminders(snapshot: FinancialSnapshot, reminder: DailyReminder) -> [PlannedNotification] {
        snapshot.subscriptions.compactMap { subscription in
            guard let day = subscription.dueDay else { return nil }
            return PlannedNotification(
                id: "subscription-\(subscription.id)",
                title: "\(subscription.name) se cobra mañana",
                body: "\(format(subscription.monthlyAmount, snapshot.currency)) al mes. Si ya no la usas, puedes cancelarla.",
                // The day before, while cancelling still avoids the charge.
                trigger: .monthly(day: max(1, day - 1), hour: 10, minute: 0)
            )
        }
    }

    private func format(_ amount: Money, _ currency: CurrencyCode) -> String {
        money.string(amount, currency: currency)
    }
}
