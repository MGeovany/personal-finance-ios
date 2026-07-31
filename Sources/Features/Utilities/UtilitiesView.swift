import SwiftUI

/// Utility reserves: one per service, each settled against its real bill.
struct UtilitiesView: View {
    let dependencies: AppDependencies
    @State private var model: UtilitiesViewModel
    @State private var editing: ChargeDraft?
    @State private var settling: UtilityEntity?
    @State private var deleting: UtilityEntity?

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        self._model = State(
            initialValue: UtilitiesViewModel(
                utilities: dependencies.utilities,
                debts: dependencies.debts,
                profiles: dependencies.profiles,
                planStore: dependencies.planStore
            )
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Layout.gap) {
                DetailHeader(title: "Servicios") {
                    IconButton(systemImage: "plus", label: "Agregar servicio", isProminent: true) {
                        editing = ChargeDraft(currency: model.currency)
                    }
                }

                summaryCard

                ForEach(model.allUtilities) { utility in
                    utilityCard(utility)
                }

                if model.allUtilities.isEmpty {
                    EmptyStateView(
                        icon: "bolt",
                        title: "Sin servicios registrados",
                        message: "Luz, agua, internet. Cada uno tiene su propia reserva y no se mezcla con tu presupuesto flexible.",
                        actionTitle: "Agregar servicio",
                        action: { editing = ChargeDraft(currency: model.currency) }
                    )
                }

                Button {
                    editing = ChargeDraft(currency: model.currency)
                } label: {
                    Label("Agregar servicio", systemImage: "plus")
                }
                .secondaryButton()
            }
            .padding(Layout.gutter)
        }
        .screenSurface()
        .sheet(item: $editing) { draft in
            ChargeEditorSheet(purpose: .utility, draft: draft, currencies: CurrencyCode.allCases) { saved in
                if model.allUtilities.contains(where: { $0.uuid == saved.id }) {
                    model.update(saved)
                } else {
                    model.add(saved)
                }
            }
        }
        .sheet(item: $settling) { utility in
            UtilitySettleSheet(
                utility: utility,
                recommendedDestination: model.recommendedDestination,
                money: dependencies.money
            ) { actual, paidByOther, destination in
                model.settle(utility, actual: actual, paidBySomeoneElse: paidByOther, destination: destination)
            }
        }
        .confirmationDrawer(
            item: $deleting,
            title: { "¿Eliminar \($0.name)?" },
            message: { _ in "Se deja de reservar dinero para este servicio cada mes." },
            confirmTitle: "Eliminar"
        ) { utility in
            model.delete(utility)
        }
    }

    private var summaryCard: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: Layout.gap) {
                StatTile(
                    label: "Reservado este mes",
                    value: dependencies.money.string(model.totalReserved, currency: model.currency)
                )
                if model.releasedThisMonth > 0 {
                    DetailRow(
                        label: "Sobrante liberado",
                        value: dependencies.money.string(model.releasedThisMonth, currency: model.currency),
                        tint: Palette.positive
                    )
                }
                Text("Los servicios no se mezclan con tu presupuesto flexible. Si un mes pagas menos, el sobrante es tuyo para colocar.")
                    .font(Typography.caption)
                    .foregroundStyle(Palette.tertiaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func utilityCard(_ utility: UtilityEntity) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: Layout.gap) {
                HStack(spacing: Layout.gap) {
                    Image(systemName: utility.icon)
                        .font(.system(size: 18))
                        .foregroundStyle(Palette.accent)
                        .frame(width: 26)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(utility.name)
                            .font(Typography.label)
                            .foregroundStyle(Palette.primaryText)
                        Text(subtitle(for: utility))
                            .font(Typography.caption)
                            .foregroundStyle(Palette.tertiaryText)
                    }

                    Spacer()

                    Text(dependencies.money.string(utility.estimatedAmount, currency: utility.currency))
                        .font(Typography.amount)
                        .foregroundStyle(Palette.primaryText)
                }

                if let reading = model.reading(for: utility), reading.isSettled {
                    RowDivider()
                    DetailRow(
                        label: reading.paidBySomeoneElse ? "Lo pagó otra persona" : "Monto real",
                        value: reading.paidBySomeoneElse
                            ? "—"
                            : dependencies.money.string(reading.actualAmount ?? 0, currency: utility.currency)
                    )
                    DetailRow(
                        label: reading.difference >= 0 ? "Sobrante" : "Excedente",
                        value: dependencies.money.string(abs(reading.difference), currency: utility.currency),
                        tint: reading.difference >= 0 ? Palette.positive : Palette.caution
                    )
                } else {
                    Button("Registrar monto real") { settling = utility }
                        .secondaryButton()
                }

                if let suggestion = model.suggestedEstimate(for: utility) {
                    InfoBanner(
                        message: "Tus facturas promedian \(dependencies.money.string(suggestion, currency: utility.currency)). ¿Ajustamos la reserva?",
                        severity: .info,
                        action: (title: "Ajustar", handler: { model.adoptSuggestedEstimate(for: utility) })
                    )
                }
            }
        }
        .contextMenu {
            Button("Editar") { editing = ChargeDraft(utility) }
            Button("Eliminar", role: .destructive) { deleting = utility }
        }
    }

    private func subtitle(for utility: UtilityEntity) -> String {
        var parts = [utility.frequency.label]
        if let day = utility.dueDay { parts.append("día \(day)") }
        if model.isSettled(utility) { parts.append("registrado") }
        return parts.joined(separator: " · ")
    }
}
