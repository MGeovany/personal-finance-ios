import Foundation

/// Everything the setup flow collects, held as one value until the user confirms.
///
/// Nothing is written while the user is still filling this in, so abandoning
/// setup halfway leaves no half-configured app behind.
struct OnboardingDraft: Equatable {
    var name: String = ""
    var currency: CurrencyCode = .hnl
    var primaryIncome: Money = 0
    var otherIncomes: [ChargeDraft] = []

    /// The monthly payments the user ticked, and what each one costs. Kept as
    /// templates rather than rows so the two questions. Which ones, then how much . 
    /// can be asked one at a time.
    var commitments: Set<CommitmentTemplate> = []
    var commitmentAmounts: [CommitmentTemplate: Money] = [:]
    /// Named streaming services (Netflix, Disney+…) when the user breaks the
    /// total down. Empty means they entered a single Streaming amount instead.
    var streamingDetails: [ChargeDraft] = []
    /// Anything the offered list did not cover, entered by hand.
    var customCommitments: [ChargeDraft] = []

    /// Declared monthly spend per category key.
    var categoryBaselines: [String: Money] = [:]
    var groceryMode: GroceryMode = .recommended

    var emergencyFund: Money = 0
    var savings: Money = 0

    var debts: [DebtDraft] = []
    /// Credit cards are collected one by one on the amounts step, so selecting the
    /// kind does not create a blank row. It only opens that section.
    var wantsCreditCards = false
    /// Set when the user says outright that they have none, which is a different
    /// answer from not having filled the step in yet.
    var hasNoDebts = false

    var goals: [GoalDraft] = []
    var hasNoGoals = false

    var remindersEnabled = true
    var reminderHour = 21

    /// When the money arrives. Nil until answered, and answering is optional: the app
    /// works without it, it just cannot be in the right place on the right day.
    var paydaySchedule: PaydaySchedule?

    /// Income is the one thing a plan cannot be built without.
    var hasMinimumViableData: Bool { primaryIncome > 0 }

    // MARK: - Charges
    //
    // The three lists storage expects, assembled from the templates. Derived rather
    // than stored so ticking a box in one place cannot fall out of step with the
    // amounts in another.

    var fixedExpenses: [ChargeDraft] {
        charges(in: .fixedExpense) + customCommitments
    }

    var utilities: [ChargeDraft] {
        charges(in: .utility)
    }

    var subscriptions: [ChargeDraft] {
        var rows: [ChargeDraft] = []

        if commitments.contains(.streaming) {
            if streamingDetails.isEmpty {
                if let amount = commitmentAmounts[.streaming], amount > 0 {
                    rows.append(ChargeDraft(name: CommitmentTemplate.streaming.label, amount: amount, currency: currency))
                }
            } else {
                rows.append(contentsOf: streamingDetails.filter(\.isValid))
            }
        }

        for template in CommitmentTemplate.all(in: .subscription) where template != .streaming {
            guard commitments.contains(template),
                  let amount = commitmentAmounts[template], amount > 0 else { continue }
            rows.append(ChargeDraft(name: template.label, amount: amount, currency: currency))
        }

        return rows
    }

    private func charges(in bucket: CommitmentTemplate.Bucket) -> [ChargeDraft] {
        CommitmentTemplate.all(in: bucket)
            .filter { commitments.contains($0) }
            .compactMap { template in
                guard let amount = commitmentAmounts[template], amount > 0 else { return nil }
                return ChargeDraft(name: template.label, amount: amount, currency: currency)
            }
    }

    /// The commitments still waiting for an amount, which is what the amounts step
    /// asks about and what stops it from being marked done too early.
    var commitmentsMissingAmounts: [CommitmentTemplate] {
        CommitmentTemplate.allCases
            .filter { commitments.contains($0) }
            .filter { template in
                if template == .streaming, !streamingDetails.isEmpty {
                    return !streamingDetails.contains(where: \.isValid)
                }
                return (commitmentAmounts[template] ?? 0) <= 0
            }
    }

    // MARK: - Totals

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

    var totalMinimumPayments: Money {
        debts.reduce(Money.zero) { $0 + $1.minimumPayment }
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
