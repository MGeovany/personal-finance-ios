import Foundation

/// The plan explained in the terms the user actually spends in.
///
/// A plan holds budgets per category. Nobody thinks in "L1,500 de delivery al mes",
/// they think in "cuatro pedidos". This is that translation, computed once so the
/// screen shown right after setup and the summary on the dashboard can never disagree
/// about what the plan allows.
struct PlanBriefing: Equatable, Sendable {
    let monthlyIncome: Money
    let freedomDate: Date?
    let monthsToFreedom: Int?

    let delivery: OrderAllowance
    let outings: WeekendAllowance
    /// The buffer, for what the monthly shop did not cover: a medicine, a soap, a
    /// repair. Deliberately not tied to a category so it can absorb anything.
    let unexpected: Money
    /// The card the extra payment attacks, and why it is that one.
    let priority: DebtPayment?
    /// Every debt with what it receives this month, priority one first.
    let payments: [DebtPayment]
    /// Money that leaves for savings rather than for a card, named. The cushion and each
    /// funded goal are separate destinations and the user has to be told which is which:
    /// "a tu ahorro" next to one number reads as whichever of them they had in mind.
    let transfers: [SavingsTransfer]

    /// One transfer the plan asks for this month.
    struct SavingsTransfer: Identifiable, Equatable, Sendable {
        /// Where it goes. A goal carries its own name, which the user wrote, so no part
        /// of the app has to invent a label for it.
        enum Destination: Equatable, Sendable {
            case emergencyFund
            case goal(id: UUID, name: String)
        }

        let destination: Destination
        let monthly: Money

        var id: String {
            switch destination {
            case .emergencyFund: "emergency"
            case .goal(let id, _): "goal-\(id)"
            }
        }
    }

    /// A budget expressed as a number of orders, which is how delivery is decided.
    struct OrderAllowance: Equatable, Sendable {
        let monthlyBudget: Money
        /// Whole orders the budget covers. Rounded down: half an order is not one.
        let orders: Int
        /// What one order was assumed to cost, shown so the arithmetic is checkable.
        let assumedPrice: Money
        /// True when the price came from what the user has actually spent rather than
        /// from the app's default.
        let priceFromHistory: Bool
    }

    /// A budget expressed per weekend, because that is when it gets spent.
    struct WeekendAllowance: Equatable, Sendable {
        let monthly: Money
        let perWeekend: Money
        let weekends: Int
    }

    struct DebtPayment: Identifiable, Equatable, Sendable {
        let debtID: UUID
        let name: String
        let institution: String
        /// Minimum plus the extra payment when this is the priority debt, the minimum
        /// alone otherwise.
        let monthly: Money
        let minimum: Money
        let annualRate: Double
        let isPriority: Bool
        let payoffDate: Date?

        var id: UUID { debtID }

        /// What the payment is on top of the minimum. Zero for every debt but one.
        var extra: Money { (monthly - minimum).nonNegative }
    }

    var hasDebt: Bool { !payments.isEmpty }

    /// Everything going to debt this month.
    var totalMonthlyToDebt: Money {
        payments.reduce(Money.zero) { $0 + $1.monthly }
    }
}
