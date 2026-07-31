import Foundation

/// One thing that happened, whatever kind of thing it was.
///
/// Expenses, card payments and savings transfers live in three separate stores because
/// they mean different things to the plan. To the user they are one history: "what have I
/// been doing with my money". This is that single line.
struct ActivityEntry: Identifiable, Equatable, Sendable {
    enum Kind: Equatable, Sendable {
        /// Money spent. Carries how it was paid, since a card purchase without money
        /// behind it is a different event from cash.
        case expense(method: PaymentMethod, backing: ExpenseBacking)
        /// Money sent to a debt.
        case payment
        /// Money moved into the cushion or a goal.
        case saving(destination: SavingsDestination)

        var label: String {
            switch self {
            case .expense: "Gasto"
            case .payment: "Abono"
            case .saving(let destination):
                destination == .emergencyFund ? "Ahorro" : "Meta"
            }
        }

        var icon: String {
            switch self {
            case .expense(let method, let backing):
                backing == .financed ? "creditcard.trianglebadge.exclamationmark" : method.icon
            case .payment: "arrow.down.circle"
            case .saving(let destination):
                destination == .emergencyFund ? "shield" : "target"
            }
        }

        /// Whether the money left the user's hands for good, as opposed to moving to a
        /// place that is still theirs. Spending and paying a card both reduce what they
        /// have; saving does not.
        var isSpending: Bool {
            if case .expense = self { return true }
            return false
        }
    }

    let id: String
    let kind: Kind
    /// What it was: the merchant, the card, the goal.
    let title: String
    /// Where it was filed, when that adds anything.
    let detail: String?
    let amount: Money
    let currency: CurrencyCode
    let date: Date
}

extension Array where Element == ActivityEntry {
    /// Newest first, which is the only order a history is ever read in.
    var newestFirst: [ActivityEntry] {
        sorted { $0.date > $1.date }
    }

    /// Grouped by day, for a list with date headers.
    func groupedByDay(calendar: Calendar = .current) -> [(day: Date, entries: [ActivityEntry])] {
        Dictionary(grouping: newestFirst) { calendar.startOfDay(for: $0.date) }
            .map { (day: $0.key, entries: $0.value) }
            .sorted { $0.day > $1.day }
    }
}
