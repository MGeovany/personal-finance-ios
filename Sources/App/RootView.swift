import SwiftUI

/// Decides what the user sees first: setup, the plan choice that follows it, or
/// the app itself.
struct RootView: View {
    let dependencies: AppDependencies

    @State private var phase: Phase
    /// Held in state so the draft survives every redraw of the flow.
    @State private var onboardingModel: OnboardingViewModel

    /// Setup and the first plan choice are one continuous flow, but the choice must
    /// happen *after* the data is saved — otherwise there would be no plans to compare.
    private enum Phase {
        case onboarding, planChoice, main
    }

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        self._phase = State(initialValue: dependencies.profile.hasCompletedOnboarding ? .main : .onboarding)
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
            .animation(.easeInOut(duration: 0.25), value: phase)
    }

    @ViewBuilder
    private var content: some View {
        switch phase {
        case .onboarding:
            OnboardingFlowView(model: onboardingModel, dependencies: dependencies)
                // The view model reports that it saved; routing stays here, so it
                // never needs to know a navigation stack exists.
                .onChange(of: onboardingModel.hasFinished) { _, finished in
                    if finished { phase = .planChoice }
                }

        case .planChoice:
            NavigationStack {
                PlanComparisonView(dependencies: dependencies, isInitialChoice: true) {
                    phase = .main
                }
            }

        case .main:
            MainTabView(dependencies: dependencies)
        }
    }
}
