import SwiftUI

/// What the plan allows, on the dashboard.
///
/// Same numbers as the full briefing, but short labels and no explanatory copy.
/// The full sentences live in "Ver mi plan completo".
struct PlanBriefingSection: View {
    let items: [BriefingItem]
    let paymentRows: [(payment: PlanBriefing.DebtPayment, value: String, detail: String)]
    /// Opens the full card-by-card version.
    let onOpenFull: () -> Void
    /// Takes the user where the number can be changed.
    let onEdit: (BriefingItem.Editable) -> Void

    var body: some View {
        CardSection(header: "Tu plan permite") {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                if index > 0 { RowDivider() }

                if item.id == "payments" {
                    paymentBreakdown(item)
                } else {
                    row(item)
                }
            }

            RowDivider()

            Button("Ver plan", action: onOpenFull)
                .compactButton()
        }
    }

    @ViewBuilder
    private func row(_ item: BriefingItem) -> some View {
        if let editable = item.editable {
            Button {
                onEdit(editable)
            } label: {
                HStack(alignment: .center, spacing: Layout.tightGap) {
                    BriefingRow(item: item, title: shortTitle(for: item), showsDetail: false)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Palette.tertiaryText)
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
        } else {
            BriefingRow(item: item, title: shortTitle(for: item), showsDetail: false)
        }
    }

    /// The one row that is a list: what each card receives, rather than the total.
    private func paymentBreakdown(_ item: BriefingItem) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Space.s) {
            BriefingRow(item: item, title: shortTitle(for: item), showsDetail: false)

            VStack(spacing: DesignSystem.Space.s) {
                ForEach(paymentRows, id: \.payment.id) { row in
                    DetailRow(
                        label: row.payment.name,
                        value: row.value,
                        tint: row.payment.isPriority ? Palette.primaryText : Palette.secondaryText,
                        caption: row.payment.isPriority ? "Prioridad" : "Mínimo"
                    )
                }
            }
            .padding(.leading, 34)
        }
    }

    private func shortTitle(for item: BriefingItem) -> String {
        switch item.id {
        case "delivery": "Pedidos"
        case "outings": "Salidas"
        case "unexpected": "Imprevistos"
        case "priority": "Prioridad"
        case "payments": "Abonos"
        default: item.question
        }
    }
}
