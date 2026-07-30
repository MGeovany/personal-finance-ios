import Foundation
import Observation

/// Utility reserves and their monthly reconciliation.
@MainActor
@Observable
final class UtilitiesViewModel {
    private let utilities: UtilityRepositing
    private let debts: DebtRepositing
    private let profiles: ProfileProviding
    private let planStore: PlanStore
    private let monthKeys: MonthKeyFormatter
    private let dateProvider: DateProviding

    init(
        utilities: UtilityRepositing,
        debts: DebtRepositing,
        profiles: ProfileProviding,
        planStore: PlanStore,
        monthKeys: MonthKeyFormatter = MonthKeyFormatter(),
        dateProvider: DateProviding = SystemDateProvider()
    ) {
        self.utilities = utilities
        self.debts = debts
        self.profiles = profiles
        self.planStore = planStore
        self.monthKeys = monthKeys
        self.dateProvider = dateProvider
    }

    var currency: CurrencyCode { planStore.currency }
    private var now: Date { dateProvider.now }

    var allUtilities: [UtilityEntity] { utilities.all() }

    var totalReserved: Money {
        utilities.active().reduce(Money.zero) { $0 + $1.monthlyReserve }
    }

    /// Surplus already released this month by bills that came in under the reserve.
    var releasedThisMonth: Money {
        let key = monthKeys.key(for: now)
        return utilities.all()
            .compactMap { $0.reading(forMonth: key) }
            .filter(\.isSettled)
            .reduce(Money.zero) { $0 + $1.difference.nonNegative }
    }

    func reading(for utility: UtilityEntity) -> UtilityReadingEntity? {
        utility.reading(forMonth: monthKeys.key(for: now))
    }

    func isSettled(_ utility: UtilityEntity) -> Bool {
        reading(for: utility)?.isSettled ?? false
    }

    /// Records the real bill and places any surplus where the user chose.
    func settle(
        _ utility: UtilityEntity,
        actual: Money?,
        paidBySomeoneElse: Bool,
        destination: SurplusDestination
    ) {
        let reading = utilities.settle(
            utility,
            monthOf: now,
            actual: actual,
            paidBySomeoneElse: paidBySomeoneElse,
            surplusDestination: destination
        )
        applySurplus(reading.difference.nonNegative, to: destination)
        planStore.refresh()
    }

    /// A surplus is real money, so it has to land somewhere real rather than just
    /// being reported.
    private func applySurplus(_ amount: Money, to destination: SurplusDestination) {
        guard amount > 0 else { return }

        switch destination {
        case .debt:
            guard let targetID = planStore.activePlan.nextTargetDebtID,
                  let debt = debts.debt(withID: targetID)
            else { return }
            debts.registerPayment(amount, on: debt, date: now, note: "Sobrante de servicios", wasRecommended: false)

        case .emergencyFund:
            let profile = profiles.profile()
            profile.emergencyFund += amount
            profiles.save()

        // Goals are funded from the goals screen, where the user picks which one;
        // carry-over simply stays in the month's free margin.
        case .goal, .carryOver:
            break
        }
    }

    var recommendedDestination: SurplusDestination {
        SurplusDestination.recommended(hasHighInterestDebt: planStore.snapshot.highestAnnualRate >= 0.20)
    }

    func add(_ draft: ChargeDraft) {
        let order = (utilities.all().map(\.order).max() ?? 0) + 1
        utilities.add(
            UtilityEntity(
                uuid: draft.id,
                name: draft.name,
                icon: UtilityIcon.suggestion(for: draft.name),
                estimatedAmount: draft.amount,
                currency: draft.currency,
                frequency: draft.frequency,
                dueDay: draft.day,
                order: order
            )
        )
        planStore.refresh()
    }

    func update(_ draft: ChargeDraft) {
        guard let entity = allUtilities.first(where: { $0.uuid == draft.id }) else { return }
        entity.name = draft.name
        entity.estimatedAmount = draft.amount
        entity.currency = draft.currency
        entity.frequency = draft.frequency
        entity.dueDay = draft.day
        entity.icon = UtilityIcon.suggestion(for: draft.name)
        utilities.save()
        planStore.refresh()
    }

    func delete(_ utility: UtilityEntity) {
        utilities.delete(utility)
        planStore.refresh()
    }

    /// The average of real bills, which is a better estimate than the initial guess.
    func suggestedEstimate(for utility: UtilityEntity) -> Money? {
        guard let average = utility.historicalAverage,
              abs((average - utility.estimatedAmount).doubleValue) > 1
        else { return nil }
        return average.rounded
    }

    func adoptSuggestedEstimate(for utility: UtilityEntity) {
        guard let suggestion = suggestedEstimate(for: utility) else { return }
        utility.estimatedAmount = suggestion
        utilities.save()
        planStore.refresh()
    }
}
