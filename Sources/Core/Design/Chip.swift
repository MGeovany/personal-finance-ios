import SwiftUI

/// A small pill: a status, a difficulty, a flexibility label.
struct Chip: View {
    let text: String
    var tint: Color = Palette.accent
    var icon: String?

    var body: some View {
        HStack(spacing: 4) {
            if let icon {
                Image(systemName: icon).font(.system(size: 10, weight: .semibold))
            }
            Text(text)
                .font(Typography.captionStrong)
                .lineLimit(1)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, DesignSystem.Space.s)
        .padding(.vertical, DesignSystem.Space.xxs)
        .background(Palette.surface(for: tint), in: Capsule())
        .fixedSize(horizontal: true, vertical: false)
    }
}

/// A selectable option, used for plan speeds, strategies and grocery modes.
///
/// Selection is shown by filling the pill black. Nothing else on the screen is
/// filled, so there is never a question about which one is active.
struct SelectableChip: View {
    let text: String
    let isSelected: Bool
    var tint: Color = Palette.accent
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(Typography.label)
                .foregroundStyle(isSelected ? Palette.invertedText : Palette.primaryText)
                .padding(.horizontal, DesignSystem.Space.l)
                .frame(height: 38)
                .modifier(SelectableChipSurface(isSelected: isSelected, tint: tint))
        }
        .buttonStyle(.plain)
        .animation(DesignSystem.Motion.swap, value: isSelected)
    }
}

private struct SelectableChipSurface: ViewModifier {
    let isSelected: Bool
    let tint: Color

    @ViewBuilder
    func body(content: Content) -> some View {
        if isSelected {
            if #available(iOS 26, *) {
                content.glassEffect(.regular.tint(tint).interactive(), in: Capsule())
            } else {
                content
                    .background(tint, in: Capsule())
                    .softShadow(.floating)
            }
        } else if #available(iOS 26, *) {
            content.glassEffect(.regular.interactive(), in: Capsule())
        } else {
            content
                .background(LiquidGlass.fill, in: Capsule())
                .softShadow(.raised)
        }
    }
}

/// Difficulty as rising bars, so plans can be compared without reading.
///
/// Bars rather than equal dots: dots said "one of four" and left the reader counting,
/// while a climbing shape says "a little" or "a lot" at a glance, the way signal
/// strength does.
struct DifficultyBars: View {
    let difficulty: PlanDifficulty

    private let shortest: CGFloat = 6
    private let step: CGFloat = 3
    private let width: CGFloat = 3.5

    var body: some View {
        HStack(alignment: .bottom, spacing: 3) {
            ForEach(0..<PlanDifficulty.steps, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                    .fill(index < difficulty.filledSteps ? Palette.color(for: difficulty) : Palette.surfaceSunken)
                    .frame(width: width, height: shortest + step * CGFloat(index))
            }
        }
        .animation(DesignSystem.Motion.swap, value: difficulty)
        .accessibilityElement()
        .accessibilityLabel("Dificultad: \(difficulty.label)")
    }
}
