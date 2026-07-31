import SwiftUI

/// A flat progress bar. Used for budget consumption, goal progress and debt
/// payoff, so all three read the same way.
struct ProgressBarView: View {
    let fraction: Double
    var tint: Color = Palette.accent
    var height: CGFloat = 8
    /// When true, the fill springs in on appear.
    var animated: Bool = true

    var body: some View {
        if animated {
            AnimatedProgressBar(fraction: fraction, tint: tint, height: height)
        } else {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(Palette.surfaceSunken)
                    Capsule()
                        .fill(tint)
                        .frame(width: max(0, min(1, fraction)) * geometry.size.width)
                }
            }
            .frame(height: height)
        }
    }
}

/// Progress with its numbers above it: the shape used on every budget row.
struct LabeledProgress: View {
    let title: String
    let leadingValue: String
    let trailingValue: String
    let fraction: Double
    var tint: Color = Palette.accent
    var icon: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.tightGap) {
            HStack(spacing: Layout.tightGap) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 13))
                        .foregroundStyle(tint)
                        .frame(width: 18)
                }
                Text(title)
                    .font(Typography.label)
                    .foregroundStyle(Palette.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Spacer(minLength: Layout.tightGap)
                Text(leadingValue)
                    .font(Typography.amount)
                    .foregroundStyle(Palette.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                    .layoutPriority(1)
            }

            ProgressBarView(fraction: fraction, tint: tint)

            Text(trailingValue)
                .font(Typography.caption)
                .foregroundStyle(Palette.tertiaryText)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
