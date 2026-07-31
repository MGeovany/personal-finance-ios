import SwiftUI

/// Progress bar that fills with a spring on appear, so the number lands as motion
/// rather than a static strip.
struct AnimatedProgressBar: View {
    let fraction: Double
    var tint: Color = Palette.accent
    var height: CGFloat = 10
    /// Squared off on the trailing edge, for bars that bleed past their card.
    var flushTrailing: Bool = false

    @State private var animatedFraction: Double = 0

    private var clamped: Double { max(0, min(1, fraction)) }

    var body: some View {
        GeometryReader { geometry in
            let fillWidth = max(height, geometry.size.width * animatedFraction)
            ZStack(alignment: .leading) {
                track(fill: Palette.surfaceSunken)

                track(
                    fill: LinearGradient(
                        colors: [tint.opacity(0.85), tint],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: fillWidth)
                .shadow(color: tint.opacity(0.35), radius: 8, y: 0)
            }
        }
        .frame(height: height)
        .onAppear {
            animatedFraction = 0
            withAnimation(.spring(response: 0.72, dampingFraction: 0.78).delay(0.08)) {
                animatedFraction = clamped
            }
        }
        .onChange(of: fraction) { _, newValue in
            withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
                animatedFraction = max(0, min(1, newValue))
            }
        }
        .onChange(of: tint) { _, _ in
            withAnimation(DesignSystem.Motion.swap) {
                animatedFraction = clamped
            }
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
