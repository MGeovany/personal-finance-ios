import SwiftUI

/// Subscriptions, each with the days its cancellation would buy.
struct SubscriptionsView: View {
    let dependencies: AppDependencies
    @State private var model: SubscriptionsViewModel
    @State private var editing: ChargeDraft?

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        self._model = State(
            initialValue: SubscriptionsViewModel(
                subscriptions: dependencies.subscriptions,
                debts: dependencies.debts,
                planStore: dependencies.planStore
            )
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Layout.gap) {
                summaryCard

                if !model.unused.isEmpty {
                    InfoBanner(
                        message: "Hay \(model.unused.count) suscripción(es) que no marcas como usadas desde hace más de dos meses.",
                        severity: .caution
                    )
                }

                ForEach(model.allSubscriptions) { subscription in
                    subscriptionCard(subscription)
                }

                if model.allSubscriptions.isEmpty {
                    EmptyStateView(
                        icon: "repeat",
                        title: "Sin suscripciones",
                        message: "Agrega lo que se te cobra automáticamente cada mes.",
                        actionTitle: "Agregar suscripción",
                        action: { editing = ChargeDraft(currency: model.currency) }
                    )
                }

                Button {
                    editing = ChargeDraft(currency: model.currency)
                } label: {
                    Label("Agregar suscripción", systemImage: "plus")
                }
                .secondaryButton()
            }
            .padding(Layout.gutter)
        }
        .background(Palette.canvas)
        .navigationTitle("Suscripciones")
        .sheet(item: $editing) { draft in
            ChargeEditorSheet(purpose: .subscription, draft: draft, currencies: CurrencyCode.allCases) { saved in
                if model.allSubscriptions.contains(where: { $0.uuid == saved.id }) {
                    model.update(saved)
                } else {
                    model.add(saved)
                }
            }
        }
    }

    private var summaryCard: some View {
        CardContainer {
            HStack(spacing: Layout.gap) {
                StatTile(
                    label: "Al mes",
                    value: dependencies.money.string(model.monthlyTotal, currency: model.currency),
                    size: .medium
                )
                StatTile(
                    label: "Al año",
                    value: dependencies.money.string(model.annualTotal, currency: model.currency),
                    tint: Palette.secondaryText,
                    size: .medium
                )
            }
        }
    }

    private func subscriptionCard(_ subscription: SubscriptionEntity) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: Layout.gap) {
                HStack(spacing: Layout.gap) {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: Layout.tightGap) {
                            Text(subscription.name)
                                .font(Typography.label)
                                .foregroundStyle(Palette.primaryText)
                            if subscription.status != .active {
                                Chip(text: subscription.status.label, tint: Palette.secondaryText)
                            }
                            if !subscription.isNecessary {
                                Chip(text: "No la uso", tint: Palette.caution)
                            }
                        }
                        Text(subtitle(for: subscription))
                            .font(Typography.caption)
                            .foregroundStyle(Palette.tertiaryText)
                    }

                    Spacer()

                    Text(dependencies.money.string(subscription.amount, currency: subscription.currency))
                        .font(Typography.amount)
                        .foregroundStyle(Palette.primaryText)
                }

                // The core message of this screen: what this costs in time.
                if let impact = model.cancellationImpact(for: subscription), impact.daysEarlier > 0 {
                    Text("Cancelarla podría adelantar tu fecha libre de deuda \(dependencies.dates.days(impact.daysEarlier)).")
                        .font(Typography.caption)
                        .foregroundStyle(Palette.positive)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(spacing: Layout.tightGap) {
                    if subscription.status == .active {
                        Button("Pausar") { model.setStatus(.paused, for: subscription) }.secondaryButton()
                        Button("Cancelar") { model.setStatus(.cancelled, for: subscription) }.secondaryButton()
                    } else {
                        Button("Reactivar") { model.setStatus(.active, for: subscription) }.secondaryButton()
                    }
                }
            }
        }
        .contextMenu {
            Button("Editar") { editing = ChargeDraft(subscription) }
            Button("Marcar que la usé hoy") { model.markUsedNow(subscription) }
            Button("Eliminar", role: .destructive) { model.delete(subscription) }
        }
    }

    private func subtitle(for subscription: SubscriptionEntity) -> String {
        var parts = [subscription.frequency.label]
        if let day = subscription.chargeDay { parts.append("se cobra el \(day)") }
        if let card = model.card(for: subscription) { parts.append(card.name) }
        return parts.joined(separator: " · ")
    }
}
