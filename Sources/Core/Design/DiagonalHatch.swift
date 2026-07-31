import SwiftUI

/// Diagonal stripes (`/`), for marking something as already done or in the past.
struct DiagonalHatch: View {
    var color: Color = Palette.primaryText.opacity(0.28)
    var spacing: CGFloat = 4.5
    var lineWidth: CGFloat = 1

    var body: some View {
        Canvas { context, size in
            var path = Path()
            let span = size.width + size.height
            var origin = -size.height
            while origin < span {
                path.move(to: CGPoint(x: origin, y: size.height))
                path.addLine(to: CGPoint(x: origin + size.height, y: 0))
                origin += spacing
            }
            context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: lineWidth, lineCap: .square))
        }
        .allowsHitTesting(false)
    }
}
