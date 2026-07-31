import SwiftUI

/// A short burst of confetti, fired by changing `trigger`.
///
/// The one place the app is allowed to be loud. Registering an abono is the moment the
/// plan actually happens, and it deserves more than a row turning grey. Kept to about a
/// second, drawn behind everything it celebrates, and never hit-testable, so it cannot
/// get in the way of the next tap.
///
/// Honours Reduce Motion by simply not firing: a burst of moving shapes is exactly what
/// that setting exists to switch off.
struct ConfettiBurst: View {
    /// Anything that changes when a burst should happen. A count of registered items is
    /// the usual choice.
    let trigger: Int
    var pieceCount: Int = 26

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pieces: [Piece] = []
    @State private var progress: Double = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(pieces) { piece in
                    piece.shape
                        .fill(piece.color)
                        .frame(width: piece.size.width, height: piece.size.height)
                        .rotationEffect(.degrees(piece.rotation + piece.spin * progress))
                        .offset(
                            x: piece.direction.dx * piece.distance * progress,
                            // Squared so the pieces slow outward and fall, rather than
                            // travelling in a straight line like sparks.
                            y: piece.direction.dy * piece.distance * progress + piece.gravity * progress * progress
                        )
                        .opacity(opacity)
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                }
            }
        }
        .allowsHitTesting(false)
        .onChange(of: trigger) { _, _ in fire() }
    }

    /// Full for most of the flight, then out. Fading from the start would make the burst
    /// read as a fizzle.
    private var opacity: Double {
        progress < 0.6 ? 1 : max(0, 1 - (progress - 0.6) / 0.4)
    }

    private func fire() {
        guard !reduceMotion else { return }

        pieces = (0..<pieceCount).map { _ in Piece.random() }
        progress = 0
        withAnimation(.easeOut(duration: 1.1)) { progress = 1 }
    }

    /// One piece of paper, with everything about it decided before it starts moving so the
    /// animation itself has nothing to compute.
    fileprivate struct Piece: Identifiable {
        let id = UUID()
        let direction: CGVector
        let distance: CGFloat
        let gravity: CGFloat
        let size: CGSize
        let rotation: Double
        let spin: Double
        let color: Color
        let isRound: Bool

        var shape: AnyShape {
            isRound ? AnyShape(Circle()) : AnyShape(RoundedRectangle(cornerRadius: 1, style: .continuous))
        }

        /// Ink and the success green only. The app has no other colours, and confetti in
        /// hues that appear nowhere else would look like it came from another app.
        private static let colors: [Color] = [
            DesignSystem.Ink.ink900,
            DesignSystem.Ink.ink700,
            DesignSystem.Ink.ink300,
            DesignSystem.Feedback.success,
            DesignSystem.Feedback.success.opacity(0.6),
        ]

        static func random() -> Piece {
            let angle = Double.random(in: 0..<(2 * .pi))
            // Biased upward: paper thrown into the air, not an explosion in every direction.
            let lift = Double.random(in: 0.3...1)

            return Piece(
                direction: CGVector(dx: cos(angle), dy: sin(angle) * lift - 0.35),
                distance: CGFloat.random(in: 60...150),
                gravity: CGFloat.random(in: 90...170),
                size: CGSize(
                    width: CGFloat.random(in: 4...7),
                    height: CGFloat.random(in: 4...11)
                ),
                rotation: Double.random(in: 0..<360),
                spin: Double.random(in: -320...320),
                color: colors.randomElement() ?? DesignSystem.Ink.ink900,
                isRound: Bool.random()
            )
        }
    }
}

/// A direction, since `CGVector` is not in the standard library.
struct CGVector {
    var dx: CGFloat
    var dy: CGFloat
}

extension View {
    /// Fires confetti over this view whenever `trigger` changes.
    func confetti(trigger: Int) -> some View {
        overlay(ConfettiBurst(trigger: trigger))
    }
}
