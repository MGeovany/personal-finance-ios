import Foundation

extension GoalSnapshot {
    func updating(mode: GoalMode) -> GoalSnapshot {
        var copy = self
        copy.mode = mode
        return copy
    }

    func updating(requestedMonthly: Money) -> GoalSnapshot {
        var copy = self
        copy.requestedMonthly = requestedMonthly
        return copy
    }

    func updating(savedAmount: Money) -> GoalSnapshot {
        var copy = self
        copy.savedAmount = savedAmount
        return copy
    }
}
