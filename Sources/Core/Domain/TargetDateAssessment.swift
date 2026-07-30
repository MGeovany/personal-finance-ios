import Foundation

/// The app's verdict on a date the user picked. A target date is never accepted
/// silently: it is analysed and answered with what it would actually take.
struct TargetDateAssessment: Equatable, Sendable {
    let requestedDate: Date
    let isAchievable: Bool
    /// Total monthly payment needed to hit the date, minimums included.
    let requiredMonthlyPayment: Money
    /// What would be left for everyday spending each month.
    let allowedMonthlyVariable: Money
    let allowedWeeklyVariable: Money
    /// Categories that would have to shrink, and by how much.
    let requiredCuts: [CategoryCut]
    /// Savings that would have to be used to make the date possible.
    let savingsNeeded: Money
    /// Goals that would have to pause.
    let goalsToPause: [String]
    let difficulty: PlanDifficulty
    let totalInterest: Money
    /// When the date is out of reach, the earliest date that is.
    let earliestAchievableDate: Date?

    var isImpossibleEvenAtMaximum: Bool { !isAchievable }
}

/// A specific reduction the target date demands.
struct CategoryCut: Identifiable, Equatable, Sendable {
    let categoryKey: String
    let categoryName: String
    let from: Money
    let to: Money

    var id: String { categoryKey }
    var amount: Money { (from - to).nonNegative }
}

/// The three dates the app always offers alongside any custom one.
struct DateOptions: Equatable, Sendable {
    let fast: PlanDateOption
    let recommended: PlanDateOption
    let comfortable: PlanDateOption

    var all: [PlanDateOption] { [fast, recommended, comfortable] }
}

/// One selectable freedom date with the plan behind it.
struct PlanDateOption: Identifiable, Equatable, Sendable {
    let speed: PlanSpeed
    let label: String
    let date: Date?
    let monthlyPayment: Money
    let monthlyVariable: Money
    let difficulty: PlanDifficulty

    var id: PlanSpeed { speed }
}
