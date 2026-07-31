import SwiftUI

/// The three plans, each given room to breathe.
///
/// Reached right after setup and from settings at any time. Choosing here
/// recalculates every budget, every weekly limit and the freedom date at once.
struct PlanComparisonView: View {
    let dependencies: AppDependencies
    /// Shown after onboarding, where choosing a plan closes the flow.
    var isInitialChoice: Bool = false
    var onChosen: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    private var planStore: PlanStore { dependencies.planStore }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(.bottom, DesignSystem.Space.xxxl)

                cards

                if isInitialChoice {
                    Button("Continuar con \(planStore.activePlan.name)") {
                        onChosen?()
                    }
                    .primaryButton()
                    .padding(.top, DesignSystem.Space.xxxl)
                }
            }
            .padding(.horizontal, DesignSystem.Space.xxl)
            .padding(.top, DesignSystem.Space.l)
            .padding(.bottom, DesignSystem.Space.xxxl)
        }
        .screenSurface()
    }

    /// The initial choice has nowhere to go back to, so it drops the back button.
    @ViewBuilder
    private var header: some View {
        if isInitialChoice {
            VStack(alignment: .leading, spacing: DesignSystem.Space.m) {
                Text("Elige tu ritmo")
                    .font(Typography.display(36, .displayBold))
                    .foregroundStyle(Palette.primaryText)

                Text("Puedes cambiarlo cuando quieras.")
                    .font(Typography.text(17, .light))
                    .foregroundStyle(Palette.tertiaryText)
            }
            .padding(.top, DesignSystem.Space.l)
        } else {
            DetailHeader(title: "Comparar planes")
        }
    }

    private var cards: some View {
        VStack(spacing: DesignSystem.Space.xxl) {
            ForEach(planStore.planSet.ordered) { plan in
                PlanCard(
                    plan: plan,
                    isSelected: plan.speed == planStore.request.speed,
                    isRecommended: plan.speed == .recommended,
                    summary: dependencies.narrator.summary(
                        for: plan,
                        extraInterest: planStore.extraInterest(for: plan.speed)
                    ),
                    money: dependencies.money,
                    dates: dependencies.dates,
                    currency: planStore.currency
                ) {
                    dependencies.preferences.select(speed: plan.speed)
                }
            }
        }
    }
}
