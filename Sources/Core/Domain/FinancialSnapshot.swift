import Foundation

/// Everything the engine needs to build a plan, and nothing else.
///
/// A snapshot is a value: copying it and changing a field is exactly how the
/// "¿Qué pasa si...?" simulator works, which is why no reference types appear here.
struct FinancialSnapshot: Equatable, Sendable {
    var currency: CurrencyCode
    var primaryIncome: Money
    var otherIncome: Money
    /// Rent, school fees — obligations that are neither utilities nor debt.
    var fixedExpenses: [RecurringCharge]
    /// Electricity, water, internet. Reserved separately, never mixed into the
    /// flexible budget.
    var utilities: [RecurringCharge]
    var subscriptions: [RecurringCharge]
    var debts: [DebtSnapshot]
    var categories: [CategoryBaseline]
    var goals: [GoalSnapshot]
    var emergencyFund: Money
    var savings: Money
    /// Card purchases the user has already set money aside for. That money is
    /// spoken for and must not be offered again.
    var reservedForCards: Money
    /// Date the plan is calculated from.
    var referenceDate: Date

    var totalIncome: Money { primaryIncome + otherIncome }

    var activeDebts: [DebtSnapshot] {
        debts.filter { $0.status.participatesInProjection && $0.balance > 0 }
    }

    var totalDebt: Money {
        activeDebts.reduce(Money.zero) { $0 + $1.balance }
    }

    var totalMinimumPayments: Money {
        activeDebts.reduce(Money.zero) { $0 + $1.minimumPayment }
    }

    var visibleCategories: [CategoryBaseline] {
        categories.filter { !$0.isHidden }.sorted { $0.order < $1.order }
    }

    /// Categories funded from the monthly flexible budget.
    var flexibleCategories: [CategoryBaseline] {
        visibleCategories.filter { $0.flexibility.participatesInFlexibleBudget }
    }

    /// The monthly cost of simply existing: what the emergency fund must cover.
    var essentialMonthlyCost: Money {
        fixedExpenses.totalMonthly
            + utilities.totalMonthly
            + flexibleCategories
                .filter { $0.flexibility == .essential }
                .reduce(Money.zero) { $0 + $1.realisticBaseline }
    }

    var hasDebt: Bool { !activeDebts.isEmpty }

    /// The highest rate the user is paying, which decides whether raiding
    /// savings is worth suggesting.
    var highestAnnualRate: Double {
        activeDebts.map(\.annualRate).max() ?? 0
    }
}

extension FinancialSnapshot {
    static func empty(currency: CurrencyCode = .hnl, referenceDate: Date = Date()) -> FinancialSnapshot {
        FinancialSnapshot(
            currency: currency,
            primaryIncome: 0,
            otherIncome: 0,
            fixedExpenses: [],
            utilities: [],
            subscriptions: [],
            debts: [],
            categories: [],
            goals: [],
            emergencyFund: 0,
            savings: 0,
            reservedForCards: 0,
            referenceDate: referenceDate
        )
    }
}
