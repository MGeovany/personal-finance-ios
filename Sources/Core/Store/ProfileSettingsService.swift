import Foundation

/// The writes that change the shape of the plan itself: which speed is active,
/// which payoff strategy is used, the target date, plan names, grocery mode.
///
/// Separate from `PlanStore` because that type only reads and derives; this one
/// writes and then asks for a recalculation.
@MainActor
protocol PlanPreferencing {
    func select(speed: PlanSpeed)
    func rename(speed: PlanSpeed, to name: String)
    func select(strategy: PayoffStrategy)
    func setTargetDate(_ date: Date?)
    func setGroceryMode(_ mode: GroceryMode, mainShare: Double)
    func setCurrency(_ currency: CurrencyCode)
    func setPrimaryIncome(_ amount: Money)
    func setEmergencyFund(_ amount: Money)
    func setSavings(_ amount: Money)
    func setReminder(hour: Int, minute: Int, enabled: Bool)
    func completeOnboarding()
}

@MainActor
struct ProfileSettingsService: PlanPreferencing {
    private let profiles: ProfileProviding
    private let planStore: PlanStore

    init(profiles: ProfileProviding, planStore: PlanStore) {
        self.profiles = profiles
        self.planStore = planStore
    }

    func select(speed: PlanSpeed) {
        update { $0.selectedSpeed = speed }
    }

    func rename(speed: PlanSpeed, to name: String) {
        update { $0.rename(speed, to: name) }
    }

    func select(strategy: PayoffStrategy) {
        update { $0.strategy = strategy }
    }

    func setTargetDate(_ date: Date?) {
        update { $0.targetDate = date }
    }

    func setGroceryMode(_ mode: GroceryMode, mainShare: Double) {
        update {
            $0.groceryMode = mode
            $0.groceryMainShare = mainShare
        }
    }

    func setCurrency(_ currency: CurrencyCode) {
        update { $0.currency = currency }
    }

    func setPrimaryIncome(_ amount: Money) {
        update { $0.primaryIncome = amount }
    }

    func setEmergencyFund(_ amount: Money) {
        update { $0.emergencyFund = amount }
    }

    func setSavings(_ amount: Money) {
        update { $0.savings = amount }
    }

    func setReminder(hour: Int, minute: Int, enabled: Bool) {
        update {
            $0.reminderHour = hour
            $0.reminderMinute = minute
            $0.notificationsEnabled = enabled
        }
    }

    func completeOnboarding() {
        update { $0.hasCompletedOnboarding = true }
    }

    /// Every change lands in storage and immediately recalculates the plan, so no
    /// screen can ever show a number that no longer follows from the data.
    private func update(_ change: (ProfileEntity) -> Void) {
        change(profiles.profile())
        profiles.save()
        planStore.refresh()
    }
}
