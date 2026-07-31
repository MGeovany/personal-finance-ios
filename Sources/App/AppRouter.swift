import Foundation
import Observation

/// Which of the three top-level phases the app is in.
///
/// Held apart from `RootView` so anything that changes the app's footing. Finishing
/// setup, wiping the store. Can move the user without reaching into a view's state.
@MainActor
@Observable
final class AppRouter {
    enum Phase: Equatable {
        /// First run, or a store that was just emptied.
        case onboarding
        /// Setup is saved and the three plans are ready to compare.
        case planChoice
        /// The chosen plan explained card by card, before the app itself. Setup ends
        /// with a date and no instructions, and this is the handover.
        case briefing
        case main
    }

    var phase: Phase

    init(hasCompletedOnboarding: Bool) {
        self.phase = hasCompletedOnboarding ? .main : .onboarding
    }

    /// Back to a blank slate. Used after the store is emptied.
    func restart() {
        phase = .onboarding
    }
}
