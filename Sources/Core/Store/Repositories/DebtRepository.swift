import Foundation
import SwiftData

/// Storage for debts and their payments.
@MainActor
protocol DebtRepositing {
    func all() -> [DebtEntity]
    func debt(withID id: UUID) -> DebtEntity?
    func add(_ debt: DebtEntity)
    func delete(_ debt: DebtEntity)
    /// Registers a payment, lowers the balance and settles the debt if it reaches zero.
    func registerPayment(_ amount: Money, on debt: DebtEntity, date: Date, note: String, wasRecommended: Bool)
    /// Raises the balance, used when a card purchase has no money behind it.
    func addCharge(_ amount: Money, to debt: DebtEntity)
    func save()
}

@MainActor
struct DebtRepository: DebtRepositing {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func all() -> [DebtEntity] {
        let descriptor = FetchDescriptor<DebtEntity>(sortBy: [SortDescriptor(\.createdAt)])
        return (try? context.fetch(descriptor)) ?? []
    }

    func debt(withID id: UUID) -> DebtEntity? {
        all().first { $0.uuid == id }
    }

    func add(_ debt: DebtEntity) {
        context.insert(debt)
        save()
    }

    func delete(_ debt: DebtEntity) {
        context.delete(debt)
        save()
    }

    func registerPayment(_ amount: Money, on debt: DebtEntity, date: Date, note: String, wasRecommended: Bool) {
        let payment = DebtPaymentEntity(amount: amount, date: date, note: note, wasRecommended: wasRecommended)
        payment.debt = debt
        context.insert(payment)

        debt.balance = (debt.balance - amount).nonNegative
        // Reaching zero changes what the debt *is*, so the status follows the
        // balance rather than waiting for the user to update it by hand.
        if debt.balance == 0, !debt.status.isSettled {
            debt.status = debt.status == .payAndClose ? .pendingClosure : .paid
        }
        save()
    }

    func addCharge(_ amount: Money, to debt: DebtEntity) {
        debt.balance += amount
        if debt.status == .paid { debt.status = .active }
        save()
    }

    func save() {
        try? context.save()
    }
}
