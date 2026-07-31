import Foundation
@testable import Cero

/// Records the draft it was handed instead of writing it, so the flow can be walked
/// without a store behind it.
@MainActor
final class CommitterSpy: OnboardingCommitting {
    private(set) var committed: OnboardingDraft?

    func commit(_ draft: OnboardingDraft) {
        committed = draft
    }
}

/// Absorbs the preference writes the flow makes on its way out.
@MainActor
final class PreferencesSpy: PlanPreferencing {
    private(set) var didCompleteOnboarding = false

    func select(speed: PlanSpeed) {}
    func rename(speed: PlanSpeed, to name: String) {}
    func select(strategy: PayoffStrategy) {}
    func setTargetDate(_ date: Date?) {}
    func setGroceryMode(_ mode: GroceryMode, mainShare: Double) {}
    func setDisplayName(_ name: String) {}
    func setCurrency(_ currency: CurrencyCode) {}
    func setPrimaryIncome(_ amount: Money) {}
    func setEmergencyFund(_ amount: Money) {}
    func setSavings(_ amount: Money) {}
    func setReminder(hour: Int, minute: Int, enabled: Bool) {}

    func completeOnboarding() {
        didCompleteOnboarding = true
    }
}
