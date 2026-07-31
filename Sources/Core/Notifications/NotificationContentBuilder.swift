import Foundation

/// Decides what is worth a notification, and writes it.
///
/// The tone rule: every message is useful and direct, and none of them makes the
/// user feel bad. "¿Ya agregaste tus gastos de hoy?" is a question, not a
/// reprimand. And it says where to look.
struct NotificationContentBuilder: Sendable {
    private let money: MoneyFormatting
    private let dates: PlanDateFormatting

    init(money: MoneyFormatting = MoneyFormatter(), dates: PlanDateFormatting = PlanDateFormatter()) {
        self.money = money
        self.dates = dates
    }

    func notifications(
        for plan: FinancialPlan,
        snapshot: FinancialSnapshot,
        reminder: DailyReminder
    ) -> [PlannedNotification] {
        guard reminder.isEnabled else { return [] }

        return [dailyReview(reminder)]
            + paymentDueReminders(snapshot: snapshot, plan: plan, reminder: reminder)
            + statementReminders(snapshot: snapshot, reminder: reminder)
            + subscriptionReminders(snapshot: snapshot, reminder: reminder)
    }

    // MARK: - The nightly nudge

    private func dailyReview(_ reminder: DailyReminder) -> PlannedNotification {
        PlannedNotification(
            id: "daily-review",
            title: "¿Ya agregaste tus gastos de hoy?",
            body: "Revisa tus transacciones en Wallet y en tus aplicaciones bancarias.",
            trigger: .daily(hour: reminder.hour, minute: reminder.minute)
        )
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
