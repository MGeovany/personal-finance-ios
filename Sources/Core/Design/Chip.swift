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
            Text(text).font(Typography.caption.weight(.medium))
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(tint.opacity(0.12), in: Capsule())
    }
}

/// A selectable option, used for plan speeds, strategies and grocery modes.
struct SelectableChip: View {
    let text: String
    let isSelected: Bool
    var tint: Color = Palette.accent
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(Typography.label)
                .foregroundStyle(isSelected ? .white : Palette.primaryText)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(
                    isSelected ? tint : Palette.surfaceMuted,
                    in: RoundedRectangle(cornerRadius: Layout.chipRadius, style: .continuous)
                )
        }
        .buttonStyle(.plain)
    }
}

/// Difficulty as four dots, so plans can be compared without reading.
struct DifficultyDots: View {
    let difficulty: PlanDifficulty

    var body: some View {
        HStack(spacing: 3) {
            ForEach(1...4, id: \.self) { index in
                Circle()
                    .fill(index <= difficulty.dots ? Palette.color(for: difficulty) : Palette.surfaceMuted)
                    .frame(width: 6, height: 6)
            }
        }
        .accessibilityLabel("Dificultad: \(difficulty.label)")
    }
}
