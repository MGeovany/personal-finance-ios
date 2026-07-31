import SwiftUI

/// Shows setup, the plan choice that follows it, or the app itself.
///
/// The phase lives in `AppRouter` rather than here, so emptying the store can send
/// the user back to setup without this view knowing why.
struct RootView: View {
    let dependencies: AppDependencies

    /// Held in state so the draft survives every redraw of the flow.
    @State private var onboardingModel: OnboardingViewModel

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        self._onboardingModel = State(
            initialValue: OnboardingViewModel(
                committer: OnboardingCommitter(
                    profiles: dependencies.profiles,
                    incomes: dependencies.incomes,
                    fixedExpenses: dependencies.fixedExpenses,
                    utilities: dependencies.utilities,
                    subscriptions: dependencies.subscriptions,
                    debts: dependencies.debts,
                    categories: dependencies.categories,
                    goals: dependencies.goals,
                    planStore: dependencies.planStore
                ),
                preferences: dependencies.preferences
            )
        )
    }

    var body: some View {
        content
            .animation(.easeInOut(duration: 0.25), value: dependencies.router.phase)
            // Coming back to setup means the store was emptied, so the flow starts over.
            .onChange(of: dependencies.router.phase) { _, phase in
                if phase == .onboarding { onboardingModel.restart() }
            }
    }

    @ViewBuilder
    private var content: some View {
        #if DEBUG
        if ProcessInfo.processInfo.environment["CERO_GALLERY"] != nil {
            NavigationStack { ComponentGallery() }
        } else {
            phaseContent
        }
        #else
        phaseContent
        #endif
    }

    @ViewBuilder
    private var phaseContent: some View {
        switch dependencies.router.phase {
        case .onboarding:
            OnboardingFlowView(model: onboardingModel, dependencies: dependencies)
                // The view model reports that it saved; routing stays out here, so it
                // never needs to know a navigation stack exists.
                .onChange(of: onboardingModel.hasFinished) { _, finished in
                    if finished { dependencies.router.phase = .planChoice }
                }

        case .planChoice:
            NavigationStack {
                PlanComparisonView(dependencies: dependencies, isInitialChoice: true) {
                    dependencies.router.phase = .main
                }
            }

        case .main:
            MainTabView(dependencies: dependencies)
        }
    }
}
