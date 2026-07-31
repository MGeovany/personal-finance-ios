import SwiftUI

/// Destinations that sit in the cradle bar.
///
/// Ajustes is reached from Home so this list can stay two-and-two around the add
/// button, matching the reference.
enum MainTab: Hashable, CaseIterable {
    case home, debts, budget, goals

    var title: String {
        switch self {
        case .home: "Home"
        case .debts: "Deudas"
        case .budget: "Presupuesto"
        case .goals: "Metas"
        }
    }

    var icon: String {
        switch self {
        case .home: "house.fill"
        case .debts: "creditcard"
        case .budget: "chart.bar"
        case .goals: "target"
        }
    }
}

/// Floating tab bar with a center add button and two tabs on each side.
///
/// Kept to a fixed height. A freeform cradle path previously expanded to fill the
/// screen and covered Home; this version uses a plain bar plus a lifted circle.
struct MainTabBar: View {
    @Binding var selection: MainTab
    let onAdd: () -> Void

    private let fabSize: CGFloat = 56
    private let barHeight: CGFloat = 64
    private let fabGap: CGFloat = 64

    /// Extra top padding inside the safe-area inset so scroll content clears the
    /// raised center button on every tab screen.
    static let contentClearance: CGFloat = 20

    /// Scroll content bottom padding for screens that sit above the floating bar
    /// (tab roots and anything pushed from Home, like Ajustes or ¿Qué pasa si...?).
    static let scrollBottomPadding: CGFloat = 100

    var body: some View {
        ZStack(alignment: .top) {
            bar
                .padding(.top, fabSize * 0.45)

            addButton
        }
        .padding(.horizontal, DesignSystem.Space.m)
        .padding(.top, Self.contentClearance)
        .padding(.bottom, DesignSystem.Space.s)
        // Cap the inset so the shell cannot propose an unbounded height.
        .fixedSize(horizontal: false, vertical: true)
    }

    private var bar: some View {
        HStack(spacing: 0) {
            tabButton(.home)
            tabButton(.debts)

            Color.clear
                .frame(width: fabGap)

            tabButton(.budget)
            tabButton(.goals)
        }
        .frame(height: barHeight)
        .padding(.horizontal, DesignSystem.Space.s)
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Palette.surface)
                .softShadow(.floating)
        }
    }

    private var addButton: some View {
        Button(action: onAdd) {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(Palette.invertedText)
                .frame(width: fabSize, height: fabSize)
                .background(Palette.accent, in: Circle())
                .softShadow(.floating)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Agregar")
    }

    private func tabButton(_ tab: MainTab) -> some View {
        let isSelected = selection == tab

        return Button {
            selection = tab
        } label: {
            VStack(spacing: 3) {
                Image(systemName: tab.icon)
                    .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? Palette.primaryText : Palette.tertiaryText)
                    .symbolVariant(isSelected ? .fill : .none)

                Text(tab.title)
                    .font(Typography.text(10, isSelected ? .medium : .light))
                    .foregroundStyle(isSelected ? Palette.primaryText : Palette.tertiaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: barHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}
