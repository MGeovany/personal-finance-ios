import SwiftUI

/// What the user pays every month, asked as a checklist.
///
/// Showing the bills almost every household has turns recall into recognition.
/// Amounts. And anything that was not on the list. Are asked on the next step.
struct OnboardingCommitmentsStep: View {
    @Bindable var model: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.sectionGap) {
            ForEach(CommitmentTemplate.Bucket.allCases, id: \.self) { bucket in
                group(bucket)
            }
        }
    }

    private func group(_ bucket: CommitmentTemplate.Bucket) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Space.s) {
            Text(bucket.heading)
                .sectionHeaderStyle()
                .padding(.horizontal, DesignSystem.Space.xxs)

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: DesignSystem.Space.s), GridItem(.flexible())],
                spacing: DesignSystem.Space.s
            ) {
                ForEach(CommitmentTemplate.all(in: bucket)) { template in
                    ChoiceTile(
                        title: template.label,
                        icon: template.icon,
                        isSelected: model.draft.commitments.contains(template)
                    ) {
                        model.toggle(template)
                    }
                }
            }
        }
    }
}

/// The amounts for whatever was ticked, typed rather than guessed.
///
/// Suggestions belong on lifestyle questions (transporte, salidas). A rent or a
/// light bill is a number the user already knows, so the field is empty and waiting.
/// Streaming is the exception: a single total is enough, or the user can name each
/// service (Netflix, Disney+…) and the total is the sum.
struct OnboardingCommitmentAmountsStep: View {
    @Bindable var model: OnboardingViewModel

    @Environment(\.moneyFormatter) private var money
    @State private var editingCustom: ChargeDraft?
    @State private var editingStreaming: ChargeDraft?

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.sectionGap) {
            ForEach(CommitmentTemplate.Bucket.allCases, id: \.self) { bucket in
                let rows = CommitmentTemplate.all(in: bucket).filter { model.draft.commitments.contains($0) }
                if !rows.isEmpty {
                    CardSection(header: bucket.heading) {
                        ForEach(Array(rows.enumerated()), id: \.element) { index, template in
                            if index > 0 { RowDivider() }

                            if template == .streaming {
                                streamingAmount
                            } else {
                                MoneyField(
                                    title: template.label,
                                    amount: Binding(
                                        get: { model.amount(for: template) },
                                        set: { model.setAmount($0, for: template) }
                                    ),
                                    currency: model.draft.currency,
                                    caption: template.amountCaption
                                )
                            }
                        }
                    }
                }
            }

            custom
        }
        .sheet(item: $editingStreaming) { draft in
            ChargeEditorSheet(purpose: .subscription, draft: draft, currencies: CurrencyCode.allCases) { saved in
                model.addStreamingDetail(saved)
            }
        }
    }

    /// Total alone, or a named list. Whichever the user finds easier to recall.
    private var streamingAmount: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Space.m) {
            if model.draft.streamingDetails.isEmpty {
                MoneyField(
                    title: "Streaming",
                    amount: Binding(
                        get: { model.amount(for: .streaming) },
                        set: { model.setAmount($0, for: .streaming) }
                    ),
                    currency: model.draft.currency,
                    caption: "Puedes poner solo el total, o agregar cada servicio."
                )
            } else {
                VStack(alignment: .leading, spacing: DesignSystem.Space.s) {
                    HStack {
                        Text("Streaming").fieldLabel()
                        Spacer()
                        Text(money.string(model.amount(for: .streaming), currency: model.draft.currency))
                            .font(Typography.amount)
                            .foregroundStyle(Palette.primaryText)
                            .contentTransition(.numericText())
                    }

                    Text("Total de lo que agregaste.")
                        .font(Typography.caption)
                        .foregroundStyle(Palette.tertiaryText)
                }

                ForEach(model.draft.streamingDetails) { charge in
                    ChoiceCard(
                        title: charge.name,
                        trailing: money.string(charge.amount, currency: charge.currency),
                        isSelected: true
                    ) {
                        model.removeStreamingDetail(charge)
                    }
                }
            }

            Button {
                editingStreaming = ChargeDraft(currency: model.draft.currency)
            } label: {
                Label("Agregar detalle", systemImage: "plus")
                    .font(Typography.label)
                    .foregroundStyle(Palette.primaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, DesignSystem.Space.xxs)
            }
            .buttonStyle(.plain)
        }
    }

    private var custom: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Space.s) {
            ForEach(model.draft.customCommitments) { charge in
                ChoiceCard(
                    title: charge.name,
                    detail: charge.frequency.label,
                    trailing: money.string(charge.amount, currency: charge.currency),
                    isSelected: true
                ) {
                    model.removeCustomCommitment(charge)
                }
            }

            ChoiceCard(
                title: "Otro pago mensual",
                detail: "Algo que no está en la lista.",
                icon: "plus",
                showsSelection: false
            ) {
                editingCustom = ChargeDraft(currency: model.draft.currency)
            }
        }
        .sheet(item: $editingCustom) { draft in
            ChargeEditorSheet(purpose: .fixedExpense, draft: draft, currencies: CurrencyCode.allCases) { saved in
                model.addCustomCommitment(saved)
            }
        }
    }
}
