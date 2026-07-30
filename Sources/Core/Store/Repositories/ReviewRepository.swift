import Foundation
import SwiftData

/// Storage for completed daily, weekly and monthly reviews.
@MainActor
protocol ReviewRepositing {
    func log(forKey key: String) -> ReviewLogEntity?
    func isComplete(_ kind: ReviewKind, on date: Date) -> Bool
    /// Records a completed review, replacing any earlier record for the same period.
    func complete(
        _ kind: ReviewKind,
        on date: Date,
        checkedExternalApps: Bool,
        surplusDestination: SurplusDestination?,
        surplusAmount: Money
    )
    func save()
}

@MainActor
struct ReviewRepository: ReviewRepositing {
    private let context: ModelContext
    private let monthKeys: MonthKeyFormatter

    init(context: ModelContext, monthKeys: MonthKeyFormatter = MonthKeyFormatter()) {
        self.context = context
        self.monthKeys = monthKeys
    }

    func log(forKey key: String) -> ReviewLogEntity? {
        let descriptor = FetchDescriptor<ReviewLogEntity>(predicate: #Predicate { $0.key == key })
        return (try? context.fetch(descriptor))?.first
    }

    func isComplete(_ kind: ReviewKind, on date: Date) -> Bool {
        log(forKey: monthKeys.reviewKey(kind, for: date)) != nil
    }

    func complete(
        _ kind: ReviewKind,
        on date: Date,
        checkedExternalApps: Bool,
        surplusDestination: SurplusDestination?,
        surplusAmount: Money
    ) {
        let key = monthKeys.reviewKey(kind, for: date)

        // A period can be closed only once; re-closing it updates the decision
        // rather than piling up records.
        if let existing = log(forKey: key) {
            existing.completedAt = date
            existing.checkedExternalApps = checkedExternalApps
            existing.surplusDestination = surplusDestination
            existing.surplusAmount = surplusAmount
        } else {
            context.insert(
                ReviewLogEntity(
                    key: key,
                    kind: kind,
                    completedAt: date,
                    checkedExternalApps: checkedExternalApps,
                    surplusDestination: surplusDestination,
                    surplusAmount: surplusAmount
                )
            )
        }
        save()
    }

    func save() {
        try? context.save()
    }
}
