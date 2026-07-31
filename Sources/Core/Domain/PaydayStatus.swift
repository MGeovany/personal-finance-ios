import Foundation

/// How much of what the plan asked for has actually been registered since the payday.
///
/// The plan asks for several movements on a payday: a payment to each card, a transfer to
/// the cushion, a transfer to each funded goal. Treating the first one as "done" hides the
/// other three, which is worse than not asking at all. This counts them.
struct PaydayProgress: Equatable, Sendable {
    /// Debts that received a payment since the payday.
    let settledDebtIDs: Set<UUID>
    let isEmergencyFundSettled: Bool
    /// Goals that received a contribution since the payday.
    let settledGoalIDs: Set<UUID>
    /// How many movements the plan asked for in total.
    let expected: Int
    /// How many of them are registered.
    let registered: Int

    var isComplete: Bool { expected > 0 && registered >= expected }

    var hasStarted: Bool { registered > 0 }

    var remaining: Int { max(0, expected - registered) }

    static let none = PaydayProgress(
        settledDebtIDs: [],
        isEmergencyFundSettled: false,
        settledGoalIDs: [],
        expected: 0,
        registered: 0
    )
}

/// Where the user stands relative to their last payday.
///
/// The whole point of knowing the payday is this: the app can tell the difference between
/// "nothing to do today" and "the money landed three days ago and none of it has moved".
enum PaydayStatus: Equatable, Sendable {
    /// No schedule set, so the app has nothing to be right about.
    case notScheduled
    /// Today, with whatever has been registered so far.
    case today(progress: PaydayProgress)
    /// The payday has passed and there is still something to register.
    case pending(since: Date, days: Int, progress: PaydayProgress)
    /// Everything the plan asked for is registered. Done for this period.
    case settled(on: Date)
    /// Between paydays, with the last one settled.
    case waiting(next: Date?)

    /// After this many days with nothing registered, the app stops being polite about it
    /// and starts saying it every day.
    static let insistAfterDays = 3

    var isPayday: Bool {
        if case .today = self { return true }
        return false
    }

    var progress: PaydayProgress {
        switch self {
        case .today(let progress): progress
        case .pending(_, _, let progress): progress
        case .notScheduled, .settled, .waiting: .none
        }
    }

    /// Whether the dashboard should lead with this rather than tuck it away.
    var deservesTheTopOfTheScreen: Bool {
        switch self {
        case .today: true
        case .pending(_, let days, _): days >= 1
        case .notScheduled, .settled, .waiting: false
        }
    }

    /// Whether it has waited long enough to be repeated daily.
    ///
    /// Only when nothing at all has been registered. Somebody who paid two of their three
    /// cards is working on it and does not need a daily alarm about the third.
    var isInsistent: Bool {
        guard case .pending(_, let days, let progress) = self else { return false }
        return days >= Self.insistAfterDays && !progress.hasStarted
    }

    var daysWaiting: Int {
        switch self {
        case .pending(_, let days, _): days
        default: 0
        }
    }
}
