import Foundation

/// How the available money was split once the plan had its say.
struct SurplusAllocation: Equatable, Sendable {
    /// Per-category monthly budgets for everyday spending.
    let categories: [CategoryAllocation]
    /// Money kept aside for the unexpected.
    let buffer: Money
    /// What each secondary goal actually receives this month, which is rarely
    /// what it asked for.
    let goalFundingByID: [UUID: Money]
    /// Payment on top of every minimum. The engine of the whole plan.
    let extraDebtPayment: Money
    /// Deliberately unassigned, so the month has room to breathe.
    let freeMargin: Money
    /// Set when the plan could not fund even the floors of every category.
    let shortfall: Money

    var goalFunding: Money {
        goalFundingByID.values.reduce(Money.zero, +)
    }

    var lifestyleTotal: Money { categories.totalMonthly }

    var total: Money {
        lifestyleTotal + goalFunding + extraDebtPayment + freeMargin
    }

    /// Everyday spending money: what the weekly budget is derived from. The
    /// buffer is already one of the categories, so it is not added twice.
    var variableSpending: Money { lifestyleTotal }

    var isUnderfunded: Bool { shortfall > 0 }

    func funding(for goalID: UUID) -> Money { goalFundingByID[goalID] ?? 0 }
}
