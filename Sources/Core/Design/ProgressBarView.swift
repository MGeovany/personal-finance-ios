import SwiftUI

/// A flat progress bar. Used for budget consumption, goal progress and debt
/// payoff, so all three read the same way.
struct ProgressBarView: View {
    let fraction: Double
    var tint: Color = Palette.accent
    var height: CGFloat = 8
    /// When true, the fill springs in on appear.
    var animated: Bool = true
    /// Squared off on the trailing edge, for bars that bleed past their card.
    var flushTrailing: Bool = false

    var body: some View {
        if animated {
            AnimatedProgressBar(
                fraction: fraction,
                tint: tint,
                height: height,
                flushTrailing: flushTrailing
            )
        } else {
            GeometryReader { geometry in
                let fillWidth = max(0, min(1, fraction)) * geometry.size.width
                ZStack(alignment: .leading) {
                    track(fill: Palette.surfaceSunken)
                    track(fill: tint)
                        .frame(width: fillWidth)
                }
            }
            .frame(height: height)
        }
    }

    @ViewBuilder
    private func track<S: ShapeStyle>(fill: S) -> some View {
        if flushTrailing {
            UnevenRoundedRectangle(
                topLeadingRadius: height / 2,
                bottomLeadingRadius: height / 2,
                bottomTrailingRadius: 0,
                topTrailingRadius: 0,
                style: .continuous
            )
            .fill(fill)
        } else {
            Capsule().fill(fill)
        }
    }
}

/// Progress with its numbers above it: the shape used on every budget row.
struct LabeledProgress: View {
    let title: String
    let leadingValue: String
    let trailingValue: String
    /// Optional second caption line, spaced below `trailingValue`.
    var detail: String? = nil
    var detailTint: Color = Palette.tertiaryText
    let fraction: Double
    var tint: Color = Palette.accent
    var icon: String?
    /// Pulls the bar past the card’s trailing padding so it can reach the screen edge.
    var trailingBleed: CGFloat = 0

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

            // Drawn wider than the layout slot so the card does not grow, but the
            // bar can still meet the screen edge when it overflows.
            GeometryReader { geometry in
                ProgressBarView(fraction: fraction, tint: tint, flushTrailing: trailingBleed > 0)
                    .frame(width: geometry.size.width + trailingBleed, alignment: .leading)
            }
            .frame(height: 8)

            VStack(alignment: .leading, spacing: DesignSystem.Space.s) {
                Text(trailingValue)
                    .font(Typography.caption)
                    .foregroundStyle(Palette.tertiaryText)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                    .fixedSize(horizontal: false, vertical: true)

                if let detail {
                    Text(detail)
                        .font(Typography.caption)
                        .foregroundStyle(detailTint)
                        .lineLimit(2)
                        .minimumScaleFactor(0.75)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}
