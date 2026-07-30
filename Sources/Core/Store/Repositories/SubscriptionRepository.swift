import Foundation
import SwiftData

/// Storage for subscriptions.
@MainActor
protocol SubscriptionRepositing {
    func all() -> [SubscriptionEntity]
    /// Only the ones actually being charged, which is what the plan must fund.
    func charging() -> [SubscriptionEntity]
    func subscriptions(chargedOn day: Int) -> [SubscriptionEntity]
    /// Charging but with no sign of use for a while.
    func looksUnused(now: Date) -> [SubscriptionEntity]
    func add(_ subscription: SubscriptionEntity)
    func delete(_ subscription: SubscriptionEntity)
    func save()
}

@MainActor
struct SubscriptionRepository: SubscriptionRepositing {
    private let context: ModelContext
    private let calendar: Calendar

    init(context: ModelContext, calendar: Calendar = .current) {
        self.context = context
        self.calendar = calendar
    }

    func all() -> [SubscriptionEntity] {
        let descriptor = FetchDescriptor<SubscriptionEntity>(sortBy: [SortDescriptor(\.name)])
        return (try? context.fetch(descriptor)) ?? []
    }

    func charging() -> [SubscriptionEntity] {
        all().filter(\.isCharging)
    }

    func subscriptions(chargedOn day: Int) -> [SubscriptionEntity] {
        charging().filter { $0.chargeDay == day }
    }

    func looksUnused(now: Date) -> [SubscriptionEntity] {
        charging().filter { $0.looksUnused(now: now, calendar: calendar) }
    }

    func add(_ subscription: SubscriptionEntity) {
        context.insert(subscription)
        save()
    }

    func delete(_ subscription: SubscriptionEntity) {
        context.delete(subscription)
        save()
    }

    func save() {
        try? context.save()
    }
}
