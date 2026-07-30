import SwiftUI

/// The setup flow's frame: progress, the current step, and the way forward.
///
/// The frame owns navigation and the footer; each step owns only its own fields.
struct OnboardingFlowView: View {
    @Bindable var model: OnboardingViewModel
    let dependencies: AppDependencies

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: Layout.sectionGap) {
                    titleBlock
                    stepContent
                }
                .padding(.horizontal, Layout.gutter)
                .padding(.bottom, Layout.sectionGap)
            }
            .scrollDismissesKeyboard(.interactively)

            footer
        }
        .background(Palette.canvas)
        .animation(.easeInOut(duration: 0.2), value: model.step)
    }

    // MARK: - Frame

    private var header: some View {
        VStack(spacing: Layout.gap) {
            if !model.step.isFirst {
                HStack {
                    Button {
                        model.goBack()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Palette.secondaryText)
                            .frame(width: Layout.minimumTouch, height: Layout.minimumTouch, alignment: .leading)
                    }
                    Spacer()
                    Text("Paso \(model.step.progressIndex + 1) de \(OnboardingStep.progressCount)")
                        .font(Typography.caption)
                        .foregroundStyle(Palette.tertiaryText)
                    Spacer()
                    Color.clear.frame(width: Layout.minimumTouch, height: 1)
                }

                ProgressBarView(
                    fraction: Double(model.step.progressIndex + 1) / Double(OnboardingStep.progressCount),
                    height: 4
                )
            }
        }
        .padding(.horizontal, Layout.gutter)
        .padding(.top, Layout.gap)
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: Layout.tightGap) {
            Text(model.step.title)
                .font(model.step.isFirst ? Typography.hero : Typography.title)
                .foregroundStyle(Palette.primaryText)

            Text(model.step.subtitle)
                .font(Typography.body)
                .foregroundStyle(Palette.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, model.step.isFirst ? Layout.sectionGap * 2 : Layout.gap)
    }

    @ViewBuilder
    private var stepContent: some View {
        switch model.step {
        case .welcome:
            OnboardingWelcomeStep()
        case .income:
            OnboardingIncomeStep(model: model, dependencies: dependencies)
        case .fixedExpenses:
            OnboardingChargeListStep(model: model, purpose: .fixedExpense, dependencies: dependencies)
        case .utilities:
            OnboardingChargeListStep(model: model, purpose: .utility, dependencies: dependencies)
        case .subscriptions:
            OnboardingChargeListStep(model: model, purpose: .subscription, dependencies: dependencies)
        case .lifestyle:
            OnboardingLifestyleStep(model: model, dependencies: dependencies)
        case .savings:
            OnboardingSavingsStep(model: model)
        case .debts:
            OnboardingDebtsStep(model: model, dependencies: dependencies)
        case .goals:
            OnboardingGoalsStep(model: model, dependencies: dependencies)
        case .review:
            OnboardingReviewStep(model: model, dependencies: dependencies)
        }
    }

    private var footer: some View {
        VStack(spacing: Layout.tightGap) {
            Button(model.advanceTitle) {
                model.advance()
            }
            .primaryButton(isEnabled: model.canAdvance)
            .disabled(!model.canAdvance)

            if model.step == .income, model.draft.primaryIncome == 0 {
                Text("Necesitamos tu ingreso mensual para calcular cualquier plan.")
                    .font(Typography.caption)
                    .foregroundStyle(Palette.tertiaryText)
            }
        }
        .padding(Layout.gutter)
        .background(Palette.canvas)
    }
}
