import Foundation

/// Answers a date the user proposed with what it would actually take.
protocol TargetDateSolving: Sendable {
    func assess(targetDate: Date, request: PlanRequest) -> TargetDateAssessment
}
