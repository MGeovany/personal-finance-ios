import Foundation

/// Sizes the emergency fund as a multiple of essential monthly cost, and refills
/// any gap over a fixed horizon so the contribution never swallows the month.
struct EmergencyFundAdvisor: EmergencyFundAdvising {
    /// Months allowed to close the gap. Twelve keeps the monthly bite small.
    private let refillHorizonMonths: Int

    init(refillHorizonMonths: Int = 12) {
        self.refillHorizonMonths = refillHorizonMonths
    }

    func advise(for snapshot: FinancialSnapshot, tuning: PlanTuning) -> EmergencyFundAdvice {
        let recommended = snapshot.essentialMonthlyCost
            .scaled(by: tuning.emergencyMonths)
            .rounded
        let gap = (recommended - snapshot.emergencyFund).nonNegative
        let contribution = (gap / refillHorizonMonths).rounded

        let raid = savingsToDebt(snapshot: snapshot, tuning: tuning, recommendedCushion: recommended)

        return EmergencyFundAdvice(
            current: snapshot.emergencyFund,
            recommended: recommended,
            monthlyContribution: contribution,
            suggestedSavingsToDebt: raid.amount,
            justifyingAnnualRate: raid.rate
        )
    }

    /// Only savings above the cushion are ever suggested, and only when a debt is
    /// expensive enough that keeping the cash idle costs more than it protects.
    private func savingsToDebt(
        snapshot: FinancialSnapshot,
        tuning: PlanTuning,
        recommendedCushion: Money
    ) -> (amount: Money, rate: Double?) {
        guard tuning.suggestsUsingSavings, snapshot.hasDebt else { return (0, nil) }

        let rate = snapshot.highestAnnualRate
        guard rate >= tuning.savingsRaidAPRThreshold else { return (0, nil) }

        let cushionShortfall = (recommendedCushion - snapshot.emergencyFund).nonNegative
        let spareSavings = (snapshot.savings - cushionShortfall).nonNegative
        // Never send more than the debt itself, and never the whole balance of
        // savings: half is aggressive enough to matter without leaving nothing.
        let usable = min(spareSavings.scaled(by: 0.5), snapshot.totalDebt).rounded

        return usable > 0 ? (usable, rate) : (0, nil)
    }
}
