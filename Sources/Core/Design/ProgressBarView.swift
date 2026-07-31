import SwiftUI

/// A flat progress bar. Used for budget consumption, goal progress and debt
/// payoff, so all three read the same way.
struct ProgressBarView: View {
    let fraction: Double
    var tint: Color = Palette.accent
    var height: CGFloat = 8

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(Palette.surfaceSunken)
                Capsule()
                    .fill(tint)
                    .frame(width: max(0, min(1, fraction)) * geometry.size.width)
            }
        }
        .frame(height: height)
        .animation(.easeOut(duration: 0.25), value: fraction)
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
                Spacer(minLength: Layout.tightGap)
                Text(leadingValue)
                    .font(Typography.amount)
                    .foregroundStyle(Palette.primaryText)
            }

            ProgressBarView(fraction: fraction, tint: tint)

            Text(trailingValue)
                .font(Typography.caption)
                .foregroundStyle(Palette.tertiaryText)
        }
    }
}
