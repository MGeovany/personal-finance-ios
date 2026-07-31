import SwiftUI

/// A recurring amount as a row: name, what it costs monthly, and how to remove it.
///
/// Non-monthly charges show both figures, because "L1,200 anual" and "L100 al mes"
/// are the same fact and the user needs whichever one they are thinking in.
struct ChargeSummaryRow: View {
    let charge: ChargeDraft
    let money: MoneyFormatting
    var onTap: (() -> Void)?
    var onDelete: (() -> Void)?

    var body: some View {
        CardContainer(padding: DesignSystem.Space.l) {
            HStack(spacing: DesignSystem.Space.l) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(charge.name)
                        .font(Typography.label)
                        .foregroundStyle(Palette.primaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    if charge.frequency != .monthly {
                        Text("\(money.string(charge.amount, currency: charge.currency)) · \(charge.frequency.label.lowercased())")
                            .font(Typography.caption)
                            .foregroundStyle(Palette.tertiaryText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    } else if let day = charge.day {
                        Text("Día \(day)")
                            .font(Typography.caption)
                            .foregroundStyle(Palette.tertiaryText)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: DesignSystem.Space.s)

                Text(money.string(charge.monthlyAmount, currency: charge.currency))
                    .font(Typography.amount)
                    .foregroundStyle(Palette.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                    .layoutPriority(1)

                if let onDelete {
                    Button(action: onDelete) {
                        Image(systemName: "minus.circle")
                            .font(.system(size: 17))
                            .foregroundStyle(Palette.tertiaryText)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Eliminar \(charge.name)")
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { onTap?() }
    }
}
