import Foundation
import SwiftData

/// Access to the single profile row.
@MainActor
protocol ProfileProviding {
    /// The profile, created on first access so callers never deal with its absence.
    func profile() -> ProfileEntity
    func save()
}

/// Guarantees there is exactly one profile: if a second one ever appeared, the
/// oldest wins and the rest are discarded, because two profiles would mean two
/// contradictory plans.
@MainActor
struct ProfileRepository: ProfileProviding {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func profile() -> ProfileEntity {
        let existing = (try? context.fetch(FetchDescriptor<ProfileEntity>())) ?? []

        guard let first = existing.sorted(by: { $0.createdAt < $1.createdAt }).first else {
            let profile = ProfileEntity()
            context.insert(profile)
            save()
            return profile
        }

        for duplicate in existing where duplicate !== first {
            context.delete(duplicate)
        }
        return first
    }

    func save() {
        try? context.save()
    }
}
