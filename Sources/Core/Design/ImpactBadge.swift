import SwiftUI

/// The app's signature element: how many days a decision moves the freedom date.
///
/// Green when it pulls the date closer, amber when it pushes it out, grey when
/// nothing changes. Never red — spending money is not a moral failure, it just
/// has a consequence, and the consequence is the number shown here.
struct ImpactBadge: View {
    let impact: PlanImpact
    let dates: PlanDateFormatting
    var showsInterest: Bool = false
    var currency: CurrencyCode = .hnl
    var money: MoneyFormatting = MoneyFormatter()

    var body: some View {
        HStack(spacing: Layout.tightGap) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
            VStack(alignment: .leading, spacing: 2) {
                Text(headline)
                    .font(Typography.label)
                if showsInterest, impact.interestSaved != 0 {
                    Text(interestLine)
                        .font(Typography.caption)
                        .opacity(0.85)
                }
            }
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: Layout.chipRadius, style: .continuous))
    }

    private var headline: String {
        if impact.breaksPlan { return "El plan deja de cerrar" }
        guard impact.movesDate else { return "Tu fecha no cambia" }
        return impact.isImprovement
            ? "Adelanta \(dates.days(impact.daysEarlier))"
            : "Retrasa \(dates.days(impact.daysLater))"
    }

    private var interestLine: String {
        let amount = money.string(abs(impact.interestSaved), currency: currency)
        return impact.interestSaved > 0 ? "Ahorras \(amount) en intereses" : "Pagas \(amount) más en intereses"
    }

    private var icon: String {
        if impact.breaksPlan { return "exclamationmark.triangle.fill" }
        guard impact.movesDate else { return "equal.circle" }
        return impact.isImprovement ? "arrow.down.right.circle.fill" : "arrow.up.right.circle.fill"
    }

    private var tint: Color {
        if impact.breaksPlan { return Palette.critical }
        guard impact.movesDate else { return Palette.secondaryText }
        return impact.isImprovement ? Palette.positive : Palette.caution
    }
}
