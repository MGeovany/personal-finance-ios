import Foundation

/// Everything the setup flow collects, held as one value until the user confirms.
///
/// Nothing is written while the user is still filling this in, so abandoning
/// setup halfway leaves no half-configured app behind.
struct OnboardingDraft: Equatable {
    var currency: CurrencyCode = .hnl
    var primaryIncome: Money = 0
    var otherIncomes: [ChargeDraft] = []
    var fixedExpenses: [ChargeDraft] = []
    var utilities: [ChargeDraft] = []
    var subscriptions: [ChargeDraft] = []
    /// Declared monthly spend per category key.
    var categoryBaselines: [String: Money] = [:]
    var emergencyFund: Money = 0
    var savings: Money = 0
    var debts: [DebtDraft] = []
    var goals: [GoalDraft] = []
    var groceryMode: GroceryMode = .recommended

    /// Income is the one thing a plan cannot be built without.
    var hasMinimumViableData: Bool { primaryIncome > 0 }

    var totalMonthlyIncome: Money {
        primaryIncome + otherIncomes.reduce(Money.zero) { $0 + $1.monthlyAmount }
    }

    var totalCommitted: Money {
        [fixedExpenses, utilities, subscriptions]
            .flatMap { $0 }
            .reduce(Money.zero) { $0 + $1.monthlyAmount }
            + debts.reduce(Money.zero) { $0 + $1.minimumPayment }
    }

    var totalDebt: Money {
        debts.reduce(Money.zero) { $0 + $1.balance }
    }

    var declaredLifestyle: Money {
        categoryBaselines.values.reduce(Money.zero, +)
    }

    /// What is left after everything the user has declared. Shown live during
    /// setup so the numbers stop being abstract.
    var estimatedAvailable: Money {
        totalMonthlyIncome - totalCommitted - declaredLifestyle
    }
}
