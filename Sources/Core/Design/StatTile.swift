import SwiftUI

/// A labelled number: the app's basic unit of information.
struct StatTile: View {
    let label: String
    let value: String
    var caption: String?
    var tint: Color = Palette.primaryText
    var size: Size = .medium

    enum Size {
        case hero, medium, small

        var font: Font {
            switch self {
            case .hero: Typography.hero
            case .medium: Typography.statistic
            case .small: Typography.amount
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.tightGap) {
            Text(label)
                .font(Typography.label)
                .foregroundStyle(Palette.secondaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(value)
                .font(size.font)
                .foregroundStyle(tint)
                .minimumScaleFactor(0.55)
                .lineLimit(1)

            if let caption {
                Text(caption)
                    .font(Typography.caption)
                    .foregroundStyle(Palette.tertiaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
