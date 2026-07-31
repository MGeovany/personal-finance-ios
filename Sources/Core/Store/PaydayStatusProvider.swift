import Foundation

/// Works out where the user stands relative to their payday.
@MainActor
protocol PaydayStatusProviding {
    var status: PaydayStatus { get }
    /// The schedule in force, for the screens that show or edit it.
    var schedule: PaydaySchedule? { get }
    /// The most recent payment registered against any debt, whatever its date.
    var lastRegisteredPayment: Date? { get }
}

@MainActor
struct PaydayStatusProvider: PaydayStatusProviding {
    private let profiles: ProfileProviding
    private let debts: DebtRepositing
    private let paydays: PaydayCalendar
    private let dateProvider: DateProviding

    init(
        profiles: ProfileProviding,
        debts: DebtRepositing,
        paydays: PaydayCalendar = PaydayCalendar(),
        dateProvider: DateProviding = SystemDateProvider()
    ) {
        self.profiles = profiles
        self.debts = debts
        self.paydays = paydays
        self.dateProvider = dateProvider
    }

    var schedule: PaydaySchedule? {
        profiles.profile().paydaySchedule
    }

    /// Debt payments are what the app can actually see. Money moved into savings does not
    /// carry a date anywhere yet, so a saver who never touches a card would be nagged
    /// wrongly. Until savings contributions are dated, the reminder is about cards.
    var lastRegisteredPayment: Date? {
        debts.all()
            .flatMap(\.payments)
            .map(\.date)
            .max()
    }

    var status: PaydayStatus {
        guard let schedule else { return .notScheduled }
        let now = dateProvider.now

        guard let lastPayday = paydays.lastPayday(onOrBefore: now, schedule: schedule) else {
            return .waiting(next: paydays.nextPayday(after: now, schedule: schedule))
        }

        // Registered *on or after* the payday: paying the morning of counts.
        if let payment = lastRegisteredPayment,
           dateProvider.calendar.startOfDay(for: payment) >= dateProvider.calendar.startOfDay(for: lastPayday) {
            return .registered(on: payment)
        }

        let days = dateProvider.calendar.days(from: lastPayday, to: now)
        if days == 0 { return .today(daysSinceLast: 0) }

        return .pending(since: lastPayday, days: days)
    }
}
