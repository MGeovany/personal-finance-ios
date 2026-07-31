import Foundation

/// Works out where the user stands relative to their payday.
@MainActor
protocol PaydayStatusProviding {
    var status: PaydayStatus { get }
    /// The schedule in force, for the screens that show or edit it.
    var schedule: PaydaySchedule? { get }
}

@MainActor
struct PaydayStatusProvider: PaydayStatusProviding {
    private let profiles: ProfileProviding
    private let debts: DebtRepositing
    private let savings: SavingsRepositing
    private let briefings: PlanBriefingProviding
    private let paydays: PaydayCalendar
    private let dateProvider: DateProviding

    init(
        profiles: ProfileProviding,
        debts: DebtRepositing,
        savings: SavingsRepositing,
        briefings: PlanBriefingProviding,
        paydays: PaydayCalendar = PaydayCalendar(),
        dateProvider: DateProviding = SystemDateProvider()
    ) {
        self.profiles = profiles
        self.debts = debts
        self.savings = savings
        self.briefings = briefings
        self.paydays = paydays
        self.dateProvider = dateProvider
    }

    var schedule: PaydaySchedule? {
        profiles.profile().paydaySchedule
    }

    var status: PaydayStatus {
        guard let schedule else { return .notScheduled }
        let now = dateProvider.now

        guard let lastPayday = paydays.lastPayday(onOrBefore: now, schedule: schedule) else {
            return .waiting(next: paydays.nextPayday(after: now, schedule: schedule))
        }

        let progress = progress(since: lastPayday)

        // Only when every movement the plan asked for is registered. One payment out of
        // four is progress, not completion, and hiding the card there is how the other
        // three get forgotten.
        if progress.isComplete {
            return .settled(on: now)
        }

        let days = dateProvider.calendar.days(from: lastPayday, to: now)
        return days == 0
            ? .today(progress: progress)
            : .pending(since: lastPayday, days: days, progress: progress)
    }

    /// What has been registered since the payday, against what the plan asked for.
    private func progress(since payday: Date) -> PaydayProgress {
        let start = dateProvider.calendar.startOfDay(for: payday)
        let briefing = briefings.briefing

        let paidDebtIDs = Set(
            debts.all()
                .flatMap { debt in debt.payments.map { (debt.uuid, $0.date) } }
                .filter { dateProvider.calendar.startOfDay(for: $0.1) >= start }
                .map(\.0)
        )

        // Ninety days forward covers a future-dated entry, which the date picker allows.
        let contributions = savings.contributions(
            from: start,
            to: dateProvider.calendar.addingDays(90, to: dateProvider.now)
        )
        let emergencySettled = contributions.contains { $0.destination == .emergencyFund }
        let settledGoalIDs = Set(contributions.compactMap(\.goalID))

        let expectedDebts = briefing.payments.map(\.debtID)
        let expectedTransfers = briefing.transfers.map(\.destination)

        let registeredDebts = expectedDebts.filter(paidDebtIDs.contains).count
        let registeredTransfers = expectedTransfers.filter { destination in
            switch destination {
            case .emergencyFund: emergencySettled
            case .goal(let id, _): settledGoalIDs.contains(id)
            }
        }.count

        return PaydayProgress(
            settledDebtIDs: paidDebtIDs,
            isEmergencyFundSettled: emergencySettled,
            settledGoalIDs: settledGoalIDs,
            expected: expectedDebts.count + expectedTransfers.count,
            registered: registeredDebts + registeredTransfers
        )
    }
}
