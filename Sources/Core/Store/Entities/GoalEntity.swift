import Foundation
import SwiftData

/// A secondary goal: a trip, a car, a computer, a cushion.
@Model
final class GoalEntity {
    var uuid: UUID
    var name: String
    var icon: String
    var targetAmount: Money
    var savedAmount: Money
    var currencyRaw: String
    /// What the user would like to contribute monthly. The plan decides how much
    /// of it is affordable.
    var requestedMonthly: Money
    var targetDate: Date?
    var modeRaw: String
    var priority: Int
    var createdAt: Date
    var completedAt: Date?

    init(
        uuid: UUID = UUID(),
        name: String,
        icon: String = "target",
        targetAmount: Money,
        savedAmount: Money = 0,
        currency: CurrencyCode = .hnl,
        requestedMonthly: Money = 0,
        targetDate: Date? = nil,
        mode: GoalMode = .parallel,
        priority: Int = 0,
        createdAt: Date = Date()
    ) {
        self.uuid = uuid
        self.name = name
        self.icon = icon
        self.targetAmount = targetAmount
        self.savedAmount = savedAmount
        self.currencyRaw = currency.rawValue
        self.requestedMonthly = requestedMonthly
        self.targetDate = targetDate
        self.modeRaw = mode.rawValue
        self.priority = priority
        self.createdAt = createdAt
    }
}

extension GoalEntity {
    var currency: CurrencyCode {
        get { CurrencyCode(rawValue: currencyRaw) ?? .hnl }
        set { currencyRaw = newValue.rawValue }
    }

    var mode: GoalMode {
        get { GoalMode(rawValue: modeRaw) ?? .parallel }
        set { modeRaw = newValue.rawValue }
    }

    var remaining: Money { (targetAmount - savedAmount).nonNegative }

    var progress: Double {
        guard targetAmount > 0 else { return 0 }
        return min(1, (savedAmount / targetAmount).doubleValue)
    }

    var isComplete: Bool { targetAmount > 0 && savedAmount >= targetAmount }
}
