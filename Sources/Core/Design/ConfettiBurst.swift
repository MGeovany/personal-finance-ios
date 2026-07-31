import SwiftUI

/// Confetti falling across the whole screen, fired by changing `trigger`.
///
/// The one place the app is allowed to be loud, and the only place it is allowed to be
/// colourful. Everything else is monochrome on purpose; confetti in ink and grey reads as
/// debris rather than celebration, so this is a deliberate exception rather than a break in
/// the system.
///
/// Registering an abono is the moment the plan actually happens. It deserves more than a row
/// turning grey.
///
/// Honours Reduce Motion by simply not firing: a screen of moving shapes is exactly what that
/// setting exists to switch off.
struct ConfettiBurst: View {
    /// Anything that changes when a burst should happen. A count of registered items is the
    /// usual choice.
    let trigger: Int
    var pieceCount: Int = 70

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pieces: [Piece] = []
    @State private var progress: Double = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                ForEach(pieces) { piece in
                    piece.shape
                        .fill(piece.color)
                        .frame(width: piece.size.width, height: piece.size.height)
                        .rotation3DEffect(
                            // Flipping as it falls, so a flat rectangle reads as paper
                            // rather than a sliding tile.
                            .degrees(piece.flip * progress),
                            axis: (x: 1, y: 0.4, z: 0)
                        )
                        .rotationEffect(.degrees(piece.rotation + piece.spin * progress))
                        .position(
                            x: piece.x * geometry.size.width + sway(piece),
                            // From just above the top to just past the bottom, so no piece
                            // appears or vanishes mid-screen.
                            y: -40 + (geometry.size.height + 120) * eased(piece)
                        )
                        .opacity(opacity(piece))
                }
            }
            .ignoresSafeArea()
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onChange(of: trigger) { _, _ in fire() }
    }

    /// Pieces start at slightly different times and fall at different speeds, which is what
    /// keeps a burst from looking like a single falling sheet.
    private func eased(_ piece: Piece) -> Double {
        let local = (progress - piece.delay) / (1 - piece.delay)
        guard local > 0 else { return 0 }
        return min(1, local * piece.speed)
    }

    /// Side to side drift, because paper does not fall in a straight line.
    private func sway(_ piece: Piece) -> CGFloat {
        piece.swayWidth * CGFloat(sin(eased(piece) * piece.swayCycles * 2 * .pi))
    }

    private func opacity(_ piece: Piece) -> Double {
        let local = eased(piece)
        guard local > 0 else { return 0 }
        // Full for most of the fall, then out near the bottom.
        return local < 0.75 ? 1 : max(0, 1 - (local - 0.75) / 0.25)
    }

    private func fire() {
        guard !reduceMotion else { return }

        pieces = (0..<pieceCount).map { _ in Piece.random() }
        progress = 0
        withAnimation(.easeIn(duration: 1.8)) { progress = 1 }
    }

    /// One piece of paper, with everything about it decided before it starts moving so the
    /// animation itself has nothing to compute.
    fileprivate struct Piece: Identifiable {
        let id = UUID()
        /// Horizontal position as a fraction of the width, so it scales to any screen.
        let x: CGFloat
        let size: CGSize
        let rotation: Double
        let spin: Double
        let flip: Double
        let delay: Double
        let speed: Double
        let swayWidth: CGFloat
        let swayCycles: Double
        let color: Color
        let isRound: Bool

        var shape: AnyShape {
            isRound ? AnyShape(Circle()) : AnyShape(RoundedRectangle(cornerRadius: 1, style: .continuous))
        }

        /// A confetti palette, and the only colours in the app that do not carry meaning.
        private static let colors: [Color] = [
            Color(red: 0.95, green: 0.31, blue: 0.36),
            Color(red: 0.98, green: 0.71, blue: 0.20),
            Color(red: 0.99, green: 0.88, blue: 0.29),
            Color(red: 0.30, green: 0.76, blue: 0.51),
            Color(red: 0.25, green: 0.60, blue: 0.94),
            Color(red: 0.62, green: 0.42, blue: 0.92),
            Color(red: 0.98, green: 0.51, blue: 0.72),
        ]

        static func random() -> Piece {
            Piece(
                x: CGFloat.random(in: 0...1),
                size: CGSize(
                    width: CGFloat.random(in: 6...10),
                    height: CGFloat.random(in: 8...15)
                ),
                rotation: Double.random(in: 0..<360),
                spin: Double.random(in: -420...420),
                flip: Double.random(in: 180...720),
                // Staggered starts spread the burst over the first third of the fall.
                delay: Double.random(in: 0...0.35),
                speed: Double.random(in: 0.75...1.3),
                swayWidth: CGFloat.random(in: 10...45),
                swayCycles: Double.random(in: 0.8...2.2),
                color: colors.randomElement() ?? .orange,
                isRound: Double.random(in: 0...1) < 0.25
            )
        }
    }
}

extension View {
    /// Rains confetti over the whole screen whenever `trigger` changes.
    func confetti(trigger: Int) -> some View {
        overlay { ConfettiBurst(trigger: trigger) }
    }
}
