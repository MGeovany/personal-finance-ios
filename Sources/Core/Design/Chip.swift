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
            Text(text).font(Typography.captionStrong)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, DesignSystem.Space.s)
        .padding(.vertical, DesignSystem.Space.xxs)
        .background(Palette.surface(for: tint), in: Capsule())
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

/// Difficulty as four dots, so plans can be compared without reading.
struct DifficultyDots: View {
    let difficulty: PlanDifficulty

    var body: some View {
        HStack(spacing: 3) {
            ForEach(1...4, id: \.self) { index in
                Circle()
                    .fill(index <= difficulty.dots ? Palette.color(for: difficulty) : Palette.surfaceSunken)
                    .frame(width: 6, height: 6)
            }
        }
        .accessibilityLabel("Dificultad: \(difficulty.label)")
    }
}
