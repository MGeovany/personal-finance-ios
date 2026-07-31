import SwiftUI

/// The setup flow's frame: how far along the user is, the question, and the way
/// forward.
///
/// The frame owns navigation, the progress bar and the footer; each step owns only
/// its own answer. Steps slide in the direction of travel, which is the whole reason
/// a flow like this feels like progress instead of a form that keeps changing.
struct OnboardingFlowView: View {
    @Bindable var model: OnboardingViewModel
    let dependencies: AppDependencies

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header

                question
                    .id(model.step)
                    .transition(slide)

                footer
            }
            .background(Palette.canvas)
            .animation(DesignSystem.Motion.present, value: model.step)
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    // MARK: - Frame

    @ViewBuilder
    private var header: some View {
        if !model.step.isFirst {
            VStack(spacing: Layout.gap) {
                HStack {
                    IconButton(systemImage: "chevron.left", label: "Volver") { model.goBack() }

                    Spacer(minLength: 0)

                    // The summary is not a question, so it shows a full bar and no
                    // count rather than claiming to be the last question.
                    Text(model.step.isLast ? "Ya está" : "\(model.progress.index) de \(model.progress.total)")
                        .font(Typography.captionStrong)
                        .foregroundStyle(Palette.tertiaryText)
                        .contentTransition(.numericText())

                    Spacer(minLength: 0)

                    // Balances the back button so the counter stays centred.
                    Color.clear.frame(width: Layout.iconButton, height: 1)
                }

                ProgressBarView(
                    fraction: Double(model.progress.index) / Double(max(model.progress.total, 1)),
                    height: 4
                )
                .animation(DesignSystem.Motion.swap, value: model.progress.index)
            }
            .padding(.horizontal, Layout.gutter)
            .padding(.top, Layout.gap)
        }
    }

    @ViewBuilder
    private var question: some View {
        if model.step == .welcome {
            // Welcome owns the whole composition. Brand, line, breathing room . 
            // so the shared title chrome would only duplicate it.
            OnboardingWelcomeStep()
                .padding(.horizontal, Layout.gutter)
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: Layout.sectionGap) {
                    titleBlock
                    stepContent
                }
                .padding(.horizontal, Layout.gutter)
                .padding(.bottom, Layout.sectionGap)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: Layout.gap) {
            Text(headline)
                .font(Typography.display(32, .displayBold))
                .foregroundStyle(Palette.primaryText)
                .fixedSize(horizontal: false, vertical: true)

            if let help = model.step.help {
                Text(help)
                    .font(Typography.body)
                    .foregroundStyle(Palette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.top, Layout.sectionGap)
        // The question arrives a beat before its answers, the same way a host
        // asks before offering the options.
        .transition(.opacity.combined(with: .offset(y: 8)))
    }

    /// The income question says the name back, which is the cheapest way to show
    /// the answer was heard.
    private var headline: String {
        guard model.step == .income, !model.greetingName.isEmpty else {
            return model.step.question
        }
        return "¿Cuánto es tu ingreso total mensual, \(model.greetingName)?"
    }

    @ViewBuilder
    private var stepContent: some View {
        switch model.step {
        case .welcome:
            EmptyView()
        case .name:
            OnboardingNameStep(model: model)
        case .currency:
            OnboardingCurrencyStep(model: model)
        case .income:
            OnboardingIncomeStep(model: model)
        case .commitments:
            OnboardingCommitmentsStep(model: model)
        case .commitmentAmounts:
            OnboardingCommitmentAmountsStep(model: model)
        case .groceries:
            OnboardingSpendingStep(model: model, category: .groceries)
        case .transport:
            OnboardingSpendingStep(model: model, category: .transport)
        case .outings:
            OnboardingSpendingStep(model: model, category: .outings)
        case .debtKinds:
            OnboardingDebtKindsStep(model: model)
        case .debtAmounts:
            OnboardingDebtAmountsStep(model: model, dependencies: dependencies)
        case .savings:
            OnboardingSavingsStep(model: model)
        case .goals:
            OnboardingGoalsStep(model: model)
        case .reminders:
            OnboardingRemindersStep(model: model)
        case .review:
            OnboardingReviewStep(model: model, dependencies: dependencies)
        }
    }

    private var footer: some View {
        VStack(spacing: Layout.tightGap) {
            Button(model.advanceTitle) { model.advance() }
                .primaryButton(isEnabled: model.canAdvance)
                .disabled(!model.canAdvance)

            if let reason = model.blockedReason {
                Text(reason)
                    .font(Typography.caption)
                    .foregroundStyle(Palette.tertiaryText)
                    .multilineTextAlignment(.center)
                    .transition(.opacity)
            }
        }
        .padding(Layout.gutter)
        .background(alignment: .top) {
            // The page colour plus a faint lift, so the button never looks like it
            // is floating over content that has scrolled behind it.
            Rectangle()
                .fill(Palette.canvas)
                .ignoresSafeArea(edges: .bottom)
                .shadow(color: Color.black.opacity(0.04), radius: 10, y: -6)
        }
        .animation(DesignSystem.Motion.swap, value: model.canAdvance)
    }

    private var slide: AnyTransition {
        let leaving: Edge = model.isMovingForward ? .leading : .trailing
        let arriving: Edge = model.isMovingForward ? .trailing : .leading
        return .asymmetric(
            insertion: .move(edge: arriving).combined(with: .opacity),
            removal: .move(edge: leaving).combined(with: .opacity)
        )
    }
}
