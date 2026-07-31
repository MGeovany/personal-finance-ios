import SwiftUI

/// Edits one category's budget, and makes the user choose who pays for it.
///
/// Raising outings from L1,200 to L2,500 has to come from somewhere: either the freedom date
/// moves, or the same money comes out of another discretionary budget. Both are legitimate
/// answers and only the user knows which one they want, so the sheet shows the arithmetic
/// for each and refuses to decide.
struct CategoryBudgetSheet: View {
    let consumption: BudgetConsumption
    let model: BudgetViewModel
    let dependencies: AppDependencies

    @State private var amount: Money
    @State private var choice: Funding = .laterDate
    @Environment(\.dismiss) private var dismiss

    /// The two ways to pay for an increase.
    private enum Funding: Equatable {
        /// Let the plan absorb it. The extra debt payment shrinks and the date slips.
        case laterDate
        /// Hold the date by cutting elsewhere.
        case cutElsewhere
    }

    init(consumption: BudgetConsumption, model: BudgetViewModel, dependencies: AppDependencies) {
        self.consumption = consumption
        self.model = model
        self.dependencies = dependencies
        self._amount = State(initialValue: consumption.budget)
    }

    var body: some View {
        ModalScaffold(
            title: consumption.categoryName,
            primary: ModalAction("Guardar", isEnabled: canSave, handler: save),
            secondary: isPinned
                ? ModalAction("Dejar que el plan lo calcule") {
                    model.clearOverride(forKey: consumption.categoryKey)
                    dismiss()
                }
                : nil
        ) {
            CardSection(
                footer: "Ahora tienes \(format(consumption.budget)) y has gastado \(format(consumption.spent))."
            ) {
                MoneyField(title: "Presupuesto mensual", amount: $amount, currency: model.currency)
            }

            if isIncrease {
                fundingChoice
            } else if amount != consumption.budget {
                consequence
            }

            if isPinned {
                Text("Fijaste este presupuesto a mano, así que los planes ya no lo ajustan por velocidad.")
                    .font(Typography.caption)
                    .foregroundStyle(Palette.tertiaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .modalPresentation()
    }

    // MARK: - Raising it

    /// The choice, with the cost of each option spelled out on its own card.
    private var fundingChoice: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Space.s) {
            SectionHeader(title: "¿De dónde sale?")

            Text("Subir \(consumption.categoryName.lowercased()) \(format(rebalance.needed)) tiene que salir de algún lado. Tú eliges.")
                .font(Typography.caption)
                .foregroundStyle(Palette.tertiaryText)
                .fixedSize(horizontal: false, vertical: true)

            ChoiceCard(
                title: laterDateTitle,
                detail: "Tu presupuesto de esta categoría sube y el abono extra a tus tarjetas baja lo mismo.",
                icon: "calendar.badge.clock",
                isSelected: choice == .laterDate
            ) {
                choice = .laterDate
            }

            ChoiceCard(
                title: "Mantener mi fecha",
                detail: cutDetail,
                icon: "scissors",
                isSelected: choice == .cutElsewhere
            ) {
                guard rebalance.isPossible else { return }
                choice = .cutElsewhere
            }
            .opacity(rebalance.isPossible ? 1 : 0.4)
            .disabled(!rebalance.isPossible)

            if choice == .cutElsewhere, rebalance.isPossible {
                cutBreakdown
            }
        }
        .animation(DesignSystem.Motion.swap, value: choice)
    }

    private var laterDateTitle: String {
        let impact = model.impact(ofSetting: amount, forKey: consumption.categoryKey)
        guard impact.daysLater > 0 else { return "Mover mi fecha" }
        return "Mover mi fecha \(dependencies.dates.days(impact.daysLater))"
    }

    private var cutDetail: String {
        guard rebalance.isPossible else {
            return "No hay de dónde recortar sin tocar lo esencial. Solo queda mover la fecha."
        }
        let names = rebalance.cuts.map { $0.categoryName.lowercased() }
        let list = names.joined(separator: " y ")

        if rebalance.fromGoals > 0, !names.isEmpty {
            return "Recortando \(list), y \(format(rebalance.fromGoals)) de tus metas."
        }
        if rebalance.fromGoals > 0 {
            return "Recortando \(format(rebalance.fromGoals)) de lo que aportas a tus metas."
        }
        return "Recortando \(list)."
    }

    /// The exact cuts, because "recortando salidas" is a promise and this is the number.
    private var cutBreakdown: some View {
        CardSection(header: "Lo que se recorta") {
            ForEach(rebalance.cuts) { cut in
                DetailRow(
                    label: cut.categoryName,
                    value: "\(format(cut.from)) → \(format(cut.to))",
                    tint: Palette.secondaryText
                )
            }

            if rebalance.fromGoals > 0 {
                if !rebalance.cuts.isEmpty { RowDivider() }
                DetailRow(
                    label: "Aporte a metas",
                    value: "−\(format(rebalance.fromGoals))",
                    tint: Palette.secondaryText,
                    caption: "Tus metas avanzan más lento este mes"
                )
            }
        }
    }

    // MARK: - Lowering it

    /// A cut needs no choice: it moves the date closer, which nobody has to be asked about.
    private var consequence: some View {
        CardSection(header: "Consecuencia") {
            ImpactBadge(
                impact: model.impact(ofSetting: amount, forKey: consumption.categoryKey),
                dates: dependencies.dates,
                showsInterest: true,
                currency: model.currency,
                money: dependencies.money
            )
            Text(dependencies.narrator.datedImpact(model.impact(ofSetting: amount, forKey: consumption.categoryKey)))
                .font(Typography.caption)
                .foregroundStyle(Palette.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Saving

    private var isIncrease: Bool { amount > consumption.budget }

    private var rebalance: BudgetRebalance {
        model.rebalance(raising: consumption.categoryKey, to: amount)
    }

    private var canSave: Bool { amount != consumption.budget }

    private func save() {
        if isIncrease, choice == .cutElsewhere, rebalance.isPossible {
            model.keepDate(raising: consumption.categoryKey, to: amount, using: rebalance)
        } else {
            model.acceptLaterDate(raising: consumption.categoryKey, to: amount)
        }
        dismiss()
    }

    private var isPinned: Bool {
        model.category(forKey: consumption.categoryKey)?.budgetOverride != nil
    }

    private func format(_ value: Money) -> String {
        dependencies.money.string(value, currency: model.currency)
    }
}
