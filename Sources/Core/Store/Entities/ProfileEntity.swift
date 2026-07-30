import Foundation
import SwiftData

/// The user's settings and the single row that says which plan is active.
///
/// There is exactly one of these; `ProfileRepository` owns that invariant.
@Model
final class ProfileEntity {
    var currencyRaw: String
    var primaryIncome: Money
    var emergencyFund: Money
    var savings: Money
    var selectedSpeedRaw: String
    var strategyRaw: String
    var groceryModeRaw: String
    var groceryMainShare: Double
    /// A deadline the user set for themselves, if any.
    var targetDate: Date?
    /// Hour of the evening reminder to log the day's spending.
    var reminderHour: Int
    var reminderMinute: Int
    var notificationsEnabled: Bool
    var hasCompletedOnboarding: Bool
    /// Display names per plan speed, so all three stay renameable.
    var planNamesRaw: [String: String]
    var createdAt: Date

    init(
        currency: CurrencyCode = .hnl,
        primaryIncome: Money = 0,
        emergencyFund: Money = 0,
        savings: Money = 0,
        selectedSpeed: PlanSpeed = .recommended,
        strategy: PayoffStrategy = .recommended,
        groceryMode: GroceryMode = .recommended,
        groceryMainShare: Double = GroceryMode.recommended.defaultMainShare,
        targetDate: Date? = nil,
        reminderHour: Int = 21,
        reminderMinute: Int = 0,
        notificationsEnabled: Bool = true,
        hasCompletedOnboarding: Bool = false,
        createdAt: Date = Date()
    ) {
        self.currencyRaw = currency.rawValue
        self.primaryIncome = primaryIncome
        self.emergencyFund = emergencyFund
        self.savings = savings
        self.selectedSpeedRaw = selectedSpeed.rawValue
        self.strategyRaw = strategy.rawValue
        self.groceryModeRaw = groceryMode.rawValue
        self.groceryMainShare = groceryMainShare
        self.targetDate = targetDate
        self.reminderHour = reminderHour
        self.reminderMinute = reminderMinute
        self.notificationsEnabled = notificationsEnabled
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.planNamesRaw = Dictionary(
            uniqueKeysWithValues: PlanSpeed.allCases.map { ($0.rawValue, $0.defaultName) }
        )
        self.createdAt = createdAt
    }
}

// MARK: - Typed accessors
//
// SwiftData stores raw values; the rest of the app only ever sees the enums.

extension ProfileEntity {
    var currency: CurrencyCode {
        get { CurrencyCode(rawValue: currencyRaw) ?? .hnl }
        set { currencyRaw = newValue.rawValue }
    }

    var selectedSpeed: PlanSpeed {
        get { PlanSpeed(rawValue: selectedSpeedRaw) ?? .recommended }
        set { selectedSpeedRaw = newValue.rawValue }
    }

    var strategy: PayoffStrategy {
        get { PayoffStrategy(rawValue: strategyRaw) ?? .recommended }
        set { strategyRaw = newValue.rawValue }
    }

    var groceryMode: GroceryMode {
        get { GroceryMode(rawValue: groceryModeRaw) ?? .recommended }
        set { groceryModeRaw = newValue.rawValue }
    }

    var planNames: [PlanSpeed: String] {
        Dictionary(
            uniqueKeysWithValues: PlanSpeed.allCases.map { speed in
                (speed, planNamesRaw[speed.rawValue] ?? speed.defaultName)
            }
        )
    }

    func name(for speed: PlanSpeed) -> String {
        planNamesRaw[speed.rawValue] ?? speed.defaultName
    }

    func rename(_ speed: PlanSpeed, to name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        planNamesRaw[speed.rawValue] = trimmed.isEmpty ? speed.defaultName : trimmed
    }
}
