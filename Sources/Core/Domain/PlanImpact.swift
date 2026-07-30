import Foundation

/// The difference one decision makes. This is the app's core sentence: "this
/// moves your date by X days".
struct PlanImpact: Equatable, Sendable {
    let baselineDate: Date?
    let newDate: Date?
    /// Positive means the freedom date moves earlier.
    let daysEarlier: Int
    /// Positive means paying less interest overall.
    let interestSaved: Money
    let baselineWeeklyBudget: Money
    let newWeeklyBudget: Money
    let baselineExtraPayment: Money
    let newExtraPayment: Money
    /// Set when the decision makes the plan impossible to sustain.
    let breaksPlan: Bool

    var daysLater: Int { -daysEarlier }
    var movesDate: Bool { daysEarlier != 0 }
    var isImprovement: Bool { daysEarlier > 0 }
    var weeklyDifference: Money { newWeeklyBudget - baselineWeeklyBudget }

    static var neutral: PlanImpact {
        PlanImpact(
            baselineDate: nil,
            newDate: nil,
            daysEarlier: 0,
            interestSaved: 0,
            baselineWeeklyBudget: 0,
            newWeeklyBudget: 0,
            baselineExtraPayment: 0,
            newExtraPayment: 0,
            breaksPlan: false
        )
    }
}
