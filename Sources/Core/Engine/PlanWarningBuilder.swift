import Foundation

/// Turns the numbers into the short list of things worth saying, ordered by how
/// much they matter. Nothing here blames the user: each warning states a fact and
/// what it costs.
struct PlanWarningBuilder: PlanWarningBuilding {
    func warnings(
        snapshot: FinancialSnapshot,
        cashFlow: CashFlow,
        allocation: SurplusAllocation,
        emergency: EmergencyFundAdvice,
        projection: DebtProjection,
        goalImpacts: [GoalImpact]
    ) -> [PlanWarning] {
        var warnings: [PlanWarning] = []

        if cashFlow.isDeficit {
            warnings.append(PlanWarning(kind: .deficit(cashFlow.deficit), severity: .critical))
        }
        if allocation.isUnderfunded {
            warnings.append(PlanWarning(kind: .budgetShortfall(allocation.shortfall), severity: .critical))
        }
        if snapshot.hasDebt, !projection.isFeasible {
            warnings.append(PlanWarning(kind: .neverPaysOff, severity: .critical))
        }
        if emergency.suggestedSavingsToDebt > 0, let rate = emergency.justifyingAnnualRate {
            warnings.append(
                PlanWarning(kind: .savingsOpportunity(emergency.suggestedSavingsToDebt, annualRate: rate), severity: .info)
            )
        }
        if !emergency.isFunded, emergency.gap > 0 {
            warnings.append(PlanWarning(kind: .emergencyFundLow(gap: emergency.gap), severity: .caution))
        }

        warnings.append(contentsOf: goalWarnings(goalImpacts))
        warnings.append(contentsOf: underBudgetedCategories(snapshot))

        return warnings.sorted { $0.severity > $1.severity }
    }

    private func goalWarnings(_ impacts: [GoalImpact]) -> [PlanWarning] {
        var result: [PlanWarning] = []

        let delaying = impacts.filter(\.delaysPlan)
        if !delaying.isEmpty {
            let days = delaying.reduce(0) { $0 + $1.daysDelayed }
            result.append(
                PlanWarning(kind: .goalsDelaying(names: delaying.map(\.goalName), days: days), severity: .caution)
            )
        }

        let paused = impacts.filter { $0.mode == .paused && $0.requestedMonthly > 0 }
        if !paused.isEmpty {
            result.append(PlanWarning(kind: .goalsPaused(count: paused.count), severity: .info))
        }

        return result
    }

    /// A category the user reliably overspends is not a discipline problem, it is
    /// a budget that was set too low.
    private func underBudgetedCategories(_ snapshot: FinancialSnapshot) -> [PlanWarning] {
        snapshot.flexibleCategories
            .filter(\.isOverspentHistorically)
            .compactMap { category in
                guard let average = category.historicalAverage else { return nil }
                return PlanWarning(
                    kind: .categoryUnderBudgeted(name: category.name, suggested: average.rounded),
                    severity: .caution
                )
            }
    }
}
