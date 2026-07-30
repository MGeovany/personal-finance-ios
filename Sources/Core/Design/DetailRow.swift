import SwiftUI

/// A label on the left, a value on the right. The workhorse of every detail and
/// comparison screen.
struct DetailRow: View {
    let label: String
    let value: String
    var tint: Color = Palette.primaryText
    var icon: String?
    var caption: String?

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Layout.gap) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.tertiaryText)
                    .frame(width: 18)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(Typography.body)
                    .foregroundStyle(Palette.secondaryText)
                if let caption {
                    Text(caption)
                        .font(Typography.caption)
                        .foregroundStyle(Palette.tertiaryText)
                }
            }

            Spacer(minLength: Layout.tightGap)

            Text(value)
                .font(Typography.amount)
                .foregroundStyle(tint)
                .multilineTextAlignment(.trailing)
        }
    }
}

/// A hairline used between rows inside a card.
struct RowDivider: View {
    var body: some View {
        Rectangle()
            .fill(Palette.hairline)
            .frame(height: 1)
    }
}
