import Foundation

/// One movement the plan asks for on a payday, and whether it has been registered.
///
/// A single type rather than a tuple because it carries six things and is read by two
/// screens. And because the flag is the point: the payday card has to show what is left,
/// not just what was asked.
struct PaydayInstruction: Identifiable, Equatable {
    enum Kind: Equatable {
        case debt(UUID)
        case emergencyFund
        case goal(UUID)
    }

    let kind: Kind
    let label: String
    let amount: Money
    /// The formatted amount, so a view never needs a formatter for it.
    let value: String
    let caption: String
    let icon: String
    let isRegistered: Bool
    /// True for the card the extra payment goes to, which is the one to do first.
    let isPriority: Bool

    var id: String {
        switch kind {
        case .debt(let id): "debt-\(id)"
        case .emergencyFund: "emergency"
        case .goal(let id): "goal-\(id)"
        }
    }
}

extension PlanBriefingPresenter {
    /// Everything the plan asks the user to move this payday, in the order to do it, each
    /// marked with whether it is done.
    ///
    /// Cards first and the priority card at the top of those, because the order is the
    /// plan's advice: the expensive debt first, then the minimums, then savings.
    func instructions(_ briefing: PlanBriefing, progress: PaydayProgress) -> [PaydayInstruction] {
        let payments = briefing.payments.map { payment in
            PaydayInstruction(
                kind: .debt(payment.debtID),
                label: payment.name,
                amount: payment.monthly,
                value: amount(payment.monthly),
                caption: payment.isPriority ? "Empieza por esta" : "Solo el mínimo",
                icon: payment.isPriority ? "target" : "creditcard",
                isRegistered: progress.settledDebtIDs.contains(payment.debtID),
                isPriority: payment.isPriority
            )
        }

        let transfers = briefing.transfers.map { transfer in
            switch transfer.destination {
            case .emergencyFund:
                PaydayInstruction(
                    kind: .emergencyFund,
                    label: "Fondo de emergencia",
                    amount: transfer.monthly,
                    value: amount(transfer.monthly),
                    caption: "No es de ninguna meta",
                    icon: "shield",
                    isRegistered: progress.isEmergencyFundSettled,
                    isPriority: false
                )
            case .goal(let id, let name):
                PaydayInstruction(
                    kind: .goal(id),
                    label: "Ahorro para \(name.lowercased())",
                    amount: transfer.monthly,
                    value: amount(transfer.monthly),
                    caption: "Transfiérelo a tu ahorro",
                    icon: "target",
                    isRegistered: progress.settledGoalIDs.contains(id),
                    isPriority: false
                )
            }
        }

        return payments + transfers
    }
}
