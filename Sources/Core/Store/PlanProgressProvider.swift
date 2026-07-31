import Foundation

/// Measures how the plan is going.
@MainActor
protocol PlanProgressProviding {
    var progress: PlanProgress { get }
}

@MainActor
struct PlanProgressProvider: PlanProgressProviding {
    private let profiles: ProfileProviding
    private let debts: DebtRepositing
    private let savings: SavingsRepositing
    private let planStore: PlanStore
    private let projecting: DebtProjecting
    private let paydays: PaydayCalendar
    private let dateProvider: DateProviding

    init(
        profiles: ProfileProviding,
        debts: DebtRepositing,
        savings: SavingsRepositing,
        planStore: PlanStore,
        projecting: DebtProjecting = DebtProjector(),
        paydays: PaydayCalendar = PaydayCalendar(),
        dateProvider: DateProviding = SystemDateProvider()
    ) {
        self.profiles = profiles
        self.debts = debts
        self.savings = savings
        self.planStore = planStore
        self.projecting = projecting
        self.paydays = paydays
        self.dateProvider = dateProvider
    }

    var progress: PlanProgress {
        let profile = profiles.profile()
        let plan = planStore.activePlan
        let now = dateProvider.now
        let start = profile.planStartedAt
        // Without a recorded start, everything on record counts. Better than showing zero
        // to somebody who has been using the app since before it kept the date.
        let from = start ?? Date(timeIntervalSince1970: 0)

        return PlanProgress(
            startedOn: start,
            daysIn: start.map { dateProvider.calendar.days(from: $0, to: now) } ?? 0,
            paidToDebt: paidToDebt(since: from),
            saved: saved(since: from),
            debtAtStart: profile.debtAtPlanStart,
            debtNow: planStore.snapshot.totalDebt,
            paydaysHonoured: paydayCounts(since: from).honoured,
            paydaysPassed: paydayCounts(since: from).passed,
            freedomDate: plan.freedomDate,
            monthsToFreedom: plan.monthsToFreedom,
            interestAvoided: interestAvoided(under: plan),
            interestAhead: plan.totalInterest
        )
    }

    // MARK: - Measured

    private func paidToDebt(since date: Date) -> Money {
        debts.all()
            .flatMap(\.payments)
            .filter { $0.date >= date }
            .reduce(Money.zero) { $0 + $1.amount }
    }

    private func saved(since date: Date) -> Money {
        savings.contributions(from: date, to: dateProvider.calendar.addingDays(1, to: dateProvider.now))
            .reduce(Money.zero) { $0 + $1.amount }
    }

    /// How many paydays came and went, and how many of them had something registered.
    ///
    /// Counted from the ledgers rather than stored: a movement dated between two paydays
    /// belongs to the earlier one, which is exactly how the user thinks about it.
    private func paydayCounts(since start: Date) -> (honoured: Int, passed: Int) {
        guard let schedule = profiles.profile().paydaySchedule else { return (0, 0) }

        let calendar = dateProvider.calendar
        let now = dateProvider.now
        var cycleStarts: [Date] = []
        var cursor = paydays.lastPayday(onOrBefore: now, schedule: schedule)

        // Walk backwards through the paydays that fall inside the plan's life. Twenty four
        // is two years of monthly cycles, far past where this stops being interesting.
        while let payday = cursor, payday >= start, cycleStarts.count < 24 {
            cycleStarts.append(payday)
            cursor = paydays.lastPayday(onOrBefore: calendar.addingDays(-1, to: payday), schedule: schedule)
        }

        guard !cycleStarts.isEmpty else { return (0, 0) }

        let movements = debts.all().flatMap(\.payments).map(\.date)
            + savings.contributions(from: start, to: calendar.addingDays(1, to: now)).map(\.date)

        let honoured = cycleStarts.enumerated().filter { index, payday in
            // Up to the next payday, or up to now for the cycle still running.
            let end = index == 0 ? calendar.addingDays(1, to: now) : cycleStarts[index - 1]
            return movements.contains { $0 >= calendar.startOfDay(for: payday) && $0 < end }
        }.count

        return (honoured, cycleStarts.count)
    }

    // MARK: - Projected

    /// The difference between this plan and doing the minimum, in interest.
    ///
    /// Both sides are projections of interest not yet charged, which is why the screen
    /// calls this what it is: what the plan is expected to save, not what it has saved.
    private func interestAvoided(under plan: FinancialPlan) -> Money {
        let snapshot = planStore.snapshot
        guard snapshot.hasDebt else { return 0 }

        let minimumsOnly = projecting.project(
            debts: snapshot.debts,
            extraPayment: 0,
            strategy: plan.strategy,
            from: snapshot.referenceDate
        )

        // A minimums-only run that never pays off has no total to compare against, so the
        // honest answer is to claim nothing rather than a made up number.
        guard minimumsOnly.isFeasible else { return 0 }
        return (minimumsOnly.totalInterest - plan.totalInterest).nonNegative
    }
}
