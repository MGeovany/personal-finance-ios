import SwiftUI

/// Which kinds of debt the user has, picked from a grid.
///
/// "No tengo deudas" is an answer offered as plainly as the others, because for a
/// third of users it is the true one and making them hunt for a skip link implies
/// the app expects them to be in trouble.
struct OnboardingDebtKindsStep: View {
    @Bindable var model: OnboardingViewModel

    var body: some View {
        ChoiceStack {
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: DesignSystem.Space.s), GridItem(.flexible())],
                spacing: DesignSystem.Space.s
            ) {
                ForEach(DebtKind.allCases) { kind in
                    ChoiceTile(
                        title: kind.label,
                        icon: kind.icon,
                        isSelected: model.hasDebt(ofKind: kind)
                    ) {
                        model.toggle(kind)
                    }
                }
            }

            ChoiceCard(
                title: "No tengo deudas",
                detail: "La app te va a servir igual para presupuestar y ahorrar.",
                icon: "checkmark.circle",
                isSelected: model.draft.hasNoDebts
            ) {
                model.declareNoDebts()
                // Multi-select otherwise, so this answer advances itself instead of
                // waiting for Continuar.
                Task {
                    try? await Task.sleep(for: .milliseconds(280))
                    guard model.draft.hasNoDebts else { return }
                    model.advance()
                }
            }
            .padding(.top, Layout.tightGap)
        }
    }
}

/// The numbers for each debt that was ticked, one at a time.
///
/// Balances are offered as sizes rather than empty fields: picking "un mes de
/// sueldo" is faster and more honest than inventing a figure. The rate and the
/// minimum are filled in from what such debts usually carry, and only corrected if
/// the user knows better.
struct OnboardingDebtAmountsStep: View {
    @Bindable var model: OnboardingViewModel
    let dependencies: AppDependencies

    @State private var index = 0

    private var debts: [DebtDraft] { model.draft.debts }

    private var current: DebtDraft? {
        guard !debts.isEmpty else { return nil }
        return debts[min(index, debts.count - 1)]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.gap) {
            if debts.count > 1 {
                Text("\(min(index, debts.count - 1) + 1) de \(debts.count)")
                    .font(Typography.captionStrong)
                    .foregroundStyle(Palette.tertiaryText)
                    .contentTransition(.numericText())
            }

            if let current {
                DebtAnswerCard(model: model, debt: current, onAnswered: moveForward)
                    .id(current.id)
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        )
                    )
            }

            if model.draft.totalDebt > 0, index >= debts.count - 1 {
                CardContainer {
                    VStack(alignment: .leading, spacing: Layout.gap) {
                        DetailRow(
                            label: "Deuda total",
                            value: dependencies.money.string(model.draft.totalDebt, currency: model.draft.currency),
                            tint: Palette.debt
                        )
                        DetailRow(
                            label: "Pagos mínimos al mes",
                            value: dependencies.money.string(model.draft.totalMinimumPayments, currency: model.draft.currency)
                        )
                    }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(DesignSystem.Motion.present, value: index)
        .onAppear { index = firstUnansweredIndex }
    }

    private var firstUnansweredIndex: Int {
        debts.firstIndex { $0.balance <= 0 } ?? 0
    }

    private func moveForward() {
        if index + 1 < debts.count {
            index += 1
        }
    }
}

/// One debt: pick a balance size, confirm the rate, glance at the minimum.
private struct DebtAnswerCard: View {
    @Bindable var model: OnboardingViewModel
    let debt: DebtDraft
    var onAnswered: () -> Void

    @State private var isCustomRate = false
    @State private var showsDetails = false

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.gap) {
            HStack(spacing: Layout.gap) {
                Image(systemName: debt.kind.icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Palette.primaryText)
                    .frame(width: 28, height: 28)
                    .background(Palette.surfaceMuted, in: Circle())

                Text(debt.kind.label)
                    .font(Typography.titleSmall)
                    .foregroundStyle(Palette.primaryText)
            }

            AmountChoices(
                options: AmountBands.shares(
                    debt.kind.balanceShares,
                    of: model.draft.primaryIncome,
                    currency: model.draft.currency
                ),
                amount: Binding(
                    get: { debt.balance },
                    set: { model.setBalance($0, for: debt) }
                ),
                currency: model.draft.currency,
                customTitle: "Otra cantidad",
                customPlaceholder: "Lo que debes",
                onPick: {
                    withAnimation(DesignSystem.Motion.swap) { showsDetails = true }
                    // A short beat so the rate and minimum can be seen before the
                    // next debt slides in — enough to correct them, not enough to stop.
                    Task {
                        try? await Task.sleep(for: .milliseconds(420))
                        onAnswered()
                    }
                }
            )

            if showsDetails || debt.balance > 0 {
                details
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .onAppear { showsDetails = debt.balance > 0 }
    }

    private var details: some View {
        CardSection(header: "Detalles") {
            rates

            RowDivider()

            MoneyField(
                title: "Pago mínimo al mes",
                amount: Binding(
                    get: { debt.minimumPayment },
                    set: { model.setMinimum($0, for: debt) }
                ),
                currency: model.draft.currency
            )
        }
    }

    @ViewBuilder
    private var rates: some View {
        if debt.kind.typicalRates.count > 1 {
            VStack(alignment: .leading, spacing: DesignSystem.Space.s) {
                Text("Interés anual").fieldLabel()

                HStack(spacing: DesignSystem.Space.s) {
                    ForEach(debt.kind.typicalRates, id: \.self) { rate in
                        SelectableChip(
                            text: "\(Int(rate))%",
                            isSelected: !isCustomRate && debt.annualRatePercent == rate
                        ) {
                            isCustomRate = false
                            model.setRate(rate, for: debt)
                        }
                    }

                    SelectableChip(text: "Otra", isSelected: isCustomRate) {
                        isCustomRate = true
                    }

                    Spacer(minLength: 0)
                }

                if isCustomRate {
                    PercentField(
                        title: "La tasa de tu estado de cuenta",
                        percent: Binding(
                            get: { debt.annualRatePercent },
                            set: { model.setRate($0, for: debt) }
                        )
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .animation(DesignSystem.Motion.swap, value: isCustomRate)
            .onAppear { isCustomRate = !debt.kind.typicalRates.contains(debt.annualRatePercent) }
        } else {
            DetailRow(
                label: "Interés anual",
                value: "\(Int(debt.annualRatePercent))%"
            )
        }
    }
}
