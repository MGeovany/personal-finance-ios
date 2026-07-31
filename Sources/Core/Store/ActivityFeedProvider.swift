import Foundation

/// The one history, merged from the three ledgers.
@MainActor
protocol ActivityFeedProviding {
    /// Everything recorded in a window, newest first.
    func entries(from start: Date, to end: Date) -> [ActivityEntry]
    /// The most recent entries, whatever their date.
    func recentEntries(limit: Int) -> [ActivityEntry]
}

@MainActor
struct ActivityFeedProvider: ActivityFeedProviding {
    private let expenses: ExpenseRepositing
    private let debts: DebtRepositing
    private let savings: SavingsRepositing
    private let goals: GoalRepositing
    private let categories: CategoryRepositing
    private let profiles: ProfileProviding
    private let dateProvider: DateProviding

    init(
        expenses: ExpenseRepositing,
        debts: DebtRepositing,
        savings: SavingsRepositing,
        goals: GoalRepositing,
        categories: CategoryRepositing,
        profiles: ProfileProviding,
        dateProvider: DateProviding = SystemDateProvider()
    ) {
        self.expenses = expenses
        self.debts = debts
        self.savings = savings
        self.goals = goals
        self.categories = categories
        self.profiles = profiles
        self.dateProvider = dateProvider
    }

    func entries(from start: Date, to end: Date) -> [ActivityEntry] {
        (expenseEntries(from: start, to: end)
            + paymentEntries(from: start, to: end)
            + savingEntries(from: start, to: end))
            .newestFirst
    }

    func recentEntries(limit: Int) -> [ActivityEntry] {
        // A year back covers any history worth scrolling, and keeps the merge from
        // walking every record the app has ever stored.
        let start = dateProvider.calendar.addingMonths(-12, to: dateProvider.now)
        let end = dateProvider.calendar.addingDays(1, to: dateProvider.now)
        return Array(entries(from: start, to: end).prefix(limit))
    }

    // MARK: - The three ledgers

    private func expenseEntries(from start: Date, to end: Date) -> [ActivityEntry] {
        let names = categoryNames()

        return expenses.expenses(from: start, to: end).map { expense in
            let category = names[expense.categoryKey]

            return ActivityEntry(
                id: "expense-\(expense.uuid)",
                kind: .expense(method: expense.paymentMethod, backing: expense.backing),
                // The merchant if there is one, since that is what the user remembers.
                // Otherwise the category, which is all the app was told.
                title: expense.merchant.isEmpty ? (category ?? "Gasto") : expense.merchant,
                detail: expense.merchant.isEmpty ? nil : category,
                amount: expense.amount,
                currency: expense.currency,
                date: expense.date
            )
        }
    }

    private func paymentEntries(from start: Date, to end: Date) -> [ActivityEntry] {
        debts.all().flatMap { debt in
            debt.payments
                .filter { $0.date >= start && $0.date < end }
                .map { payment in
                    ActivityEntry(
                        id: "payment-\(debt.uuid)-\(payment.date.timeIntervalSince1970)",
                        kind: .payment,
                        title: debt.name,
                        detail: payment.note.isEmpty ? nil : payment.note,
                        amount: payment.amount,
                        currency: debt.currency,
                        date: payment.date
                    )
                }
        }
    }

    private func savingEntries(from start: Date, to end: Date) -> [ActivityEntry] {
        let goalNames = Dictionary(
            goals.all().map { ($0.uuid, $0.name) },
            uniquingKeysWith: { first, _ in first }
        )
        let currency = profiles.profile().currency

        return savings.contributions(from: start, to: end).map { contribution in
            let goalName = contribution.goalID.flatMap { goalNames[$0] }

            return ActivityEntry(
                id: "saving-\(contribution.uuid)",
                kind: .saving(destination: contribution.destination),
                title: goalName ?? contribution.destination.label,
                detail: contribution.note.isEmpty ? nil : contribution.note,
                amount: contribution.amount,
                currency: currency,
                date: contribution.date
            )
        }
    }

    private func categoryNames() -> [String: String] {
        Dictionary(
            categories.all().map { ($0.key, $0.name) },
            uniquingKeysWith: { first, _ in first }
        )
    }
}
