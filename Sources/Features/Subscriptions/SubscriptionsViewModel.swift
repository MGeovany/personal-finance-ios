import Foundation
import Observation

/// Subscriptions, and what cancelling each one would buy in days.
@MainActor
@Observable
final class SubscriptionsViewModel {
    private let subscriptions: SubscriptionRepositing
    private let debts: DebtRepositing
    private let planStore: PlanStore
    private let dateProvider: DateProviding

    init(
        subscriptions: SubscriptionRepositing,
        debts: DebtRepositing,
        planStore: PlanStore,
        dateProvider: DateProviding = SystemDateProvider()
    ) {
        self.subscriptions = subscriptions
        self.debts = debts
        self.planStore = planStore
        self.dateProvider = dateProvider
    }

    var currency: CurrencyCode { planStore.currency }

    var allSubscriptions: [SubscriptionEntity] { subscriptions.all() }

    var monthlyTotal: Money {
        subscriptions.charging().reduce(Money.zero) { $0 + $1.monthlyCost }
    }

    var annualTotal: Money {
        subscriptions.charging().reduce(Money.zero) { $0 + $1.annualCost }
    }

    var unused: [SubscriptionEntity] {
        subscriptions.looksUnused(now: dateProvider.now)
    }

    var cards: [DebtEntity] {
        debts.all().filter { $0.kind.isRevolving }
    }

    func card(for subscription: SubscriptionEntity) -> DebtEntity? {
        subscription.debtID.flatMap { debts.debt(withID: $0) }
    }

    /// What cancelling this subscription would do to the freedom date.
    ///
    /// The snapshot only carries subscriptions that are actually charging, so a
    /// paused one has nothing to simulate.
    func cancellationImpact(for subscription: SubscriptionEntity) -> PlanImpact? {
        guard subscription.isCharging else { return nil }
        return planStore.impact(of: .cancelSubscription(id: subscription.uuid)).impact
    }

    func setStatus(_ status: SubscriptionStatus, for subscription: SubscriptionEntity) {
        subscription.status = status
        subscriptions.save()
        planStore.refresh()
    }

    func markUsedNow(_ subscription: SubscriptionEntity) {
        subscription.lastUsedAt = dateProvider.now
        subscriptions.save()
    }

    func setCard(_ debtID: UUID?, for subscription: SubscriptionEntity) {
        subscription.debtID = debtID
        subscriptions.save()
    }

    func add(_ draft: ChargeDraft) {
        subscriptions.add(
            SubscriptionEntity(
                uuid: draft.id,
                name: draft.name,
                amount: draft.amount,
                currency: draft.currency,
                frequency: draft.frequency,
                chargeDay: draft.day,
                isNecessary: draft.isNecessary
            )
        )
        planStore.refresh()
    }

    func update(_ draft: ChargeDraft) {
        guard let entity = allSubscriptions.first(where: { $0.uuid == draft.id }) else { return }
        entity.name = draft.name
        entity.amount = draft.amount
        entity.currency = draft.currency
        entity.frequency = draft.frequency
        entity.chargeDay = draft.day
        entity.isNecessary = draft.isNecessary
        subscriptions.save()
        planStore.refresh()
    }

    func delete(_ subscription: SubscriptionEntity) {
        subscriptions.delete(subscription)
        planStore.refresh()
    }
}
