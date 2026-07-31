import Foundation

/// Writes a finished draft into storage.
///
/// Its own type so the view model stays about navigation and validation, and the
/// translation from draft to entities lives somewhere it can be read in one go.
@MainActor
protocol OnboardingCommitting {
    func commit(_ draft: OnboardingDraft)
}

@MainActor
struct OnboardingCommitter: OnboardingCommitting {
    private let profiles: ProfileProviding
    private let incomes: IncomeRepositing
    private let fixedExpenses: FixedExpenseRepositing
    private let utilities: UtilityRepositing
    private let subscriptions: SubscriptionRepositing
    private let debts: DebtRepositing
    private let categories: CategoryRepositing
    private let goals: GoalRepositing
    private let planStore: PlanStore

    init(
        profiles: ProfileProviding,
        incomes: IncomeRepositing,
        fixedExpenses: FixedExpenseRepositing,
        utilities: UtilityRepositing,
        subscriptions: SubscriptionRepositing,
        debts: DebtRepositing,
        categories: CategoryRepositing,
        goals: GoalRepositing,
        planStore: PlanStore
    ) {
        self.profiles = profiles
        self.incomes = incomes
        self.fixedExpenses = fixedExpenses
        self.utilities = utilities
        self.subscriptions = subscriptions
        self.debts = debts
        self.categories = categories
        self.goals = goals
        self.planStore = planStore
    }

    func commit(_ draft: OnboardingDraft) {
        writeProfile(draft)
        writeIncomes(draft)
        writeCharges(draft)
        writeCategories(draft)
        writeDebts(draft)
        writeGoals(draft)

        // The plan must exist by the time the comparison screen appears.
        planStore.refresh()
    }

    private func writeProfile(_ draft: OnboardingDraft) {
        let profile = profiles.profile()
        profile.displayName = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.currency = draft.currency
        profile.primaryIncome = draft.primaryIncome
        profile.emergencyFund = draft.emergencyFund
        profile.savings = draft.savings
        profile.groceryMode = draft.groceryMode
        profile.groceryMainShare = draft.groceryMode.defaultMainShare
        profile.notificationsEnabled = draft.remindersEnabled
        profile.reminderHour = draft.reminderHour
        profile.reminderMinute = 0
        profile.paydaySchedule = draft.paydaySchedule
        profiles.save()
    }

    private func writeIncomes(_ draft: OnboardingDraft) {
        for income in draft.otherIncomes where income.isValid {
            incomes.add(
                IncomeEntity(
                    name: income.name,
                    amount: income.amount,
                    currency: income.currency,
                    frequency: income.frequency
                )
            )
        }
    }

    private func writeCharges(_ draft: OnboardingDraft) {
        for expense in draft.fixedExpenses where expense.isValid {
            fixedExpenses.add(
                FixedExpenseEntity(
                    uuid: expense.id,
                    name: expense.name,
                    amount: expense.amount,
                    currency: expense.currency,
                    frequency: expense.frequency,
                    dueDay: expense.day
                )
            )
        }

        for (index, utility) in draft.utilities.enumerated() where utility.isValid {
            utilities.add(
                UtilityEntity(
                    uuid: utility.id,
                    name: utility.name,
                    icon: UtilityIcon.suggestion(for: utility.name),
                    estimatedAmount: utility.amount,
                    currency: utility.currency,
                    frequency: utility.frequency,
                    dueDay: utility.day,
                    order: index
                )
            )
        }

        for subscription in draft.subscriptions where subscription.isValid {
            subscriptions.add(
                SubscriptionEntity(
                    uuid: subscription.id,
                    name: subscription.name,
                    amount: subscription.amount,
                    currency: subscription.currency,
                    frequency: subscription.frequency,
                    chargeDay: subscription.day,
                    isNecessary: subscription.isNecessary
                )
            )
        }
    }

    /// Categories already exist from the default seed, so this fills in baselines
    /// rather than creating rows.
    private func writeCategories(_ draft: OnboardingDraft) {
        for (key, amount) in draft.categoryBaselines {
            guard let category = categories.category(forKey: key) else { continue }
            category.baseline = amount
        }
        categories.save()
    }

    private func writeDebts(_ draft: OnboardingDraft) {
        for debt in draft.debts where debt.isValid {
            debts.add(debt.makeEntity())
        }
    }

    private func writeGoals(_ draft: OnboardingDraft) {
        for (index, goal) in draft.goals.enumerated() where goal.isValid {
            goals.add(goal.makeEntity(priority: index))
        }
    }
}
