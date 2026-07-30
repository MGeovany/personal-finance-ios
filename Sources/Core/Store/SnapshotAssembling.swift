import Foundation

/// Turns stored data into the immutable snapshot the engine consumes.
///
/// This is the seam between persistence and calculation: above it live SwiftData
/// entities, below it only value types. Nothing in `Engine` knows SwiftData
/// exists, and nothing in the store knows how a plan is computed.
@MainActor
protocol SnapshotAssembling {
    func snapshot(referenceDate: Date) -> FinancialSnapshot
    /// The snapshot together with the profile's plan settings.
    func planRequest(referenceDate: Date) -> PlanRequest
}
