import SwiftUI

/// The plan explained one card at a time, right after setup.
///
/// Setup ends with three plans and a date, which is a lot of arithmetic and no
/// instructions. This is the handover: what the user gets to spend, on what, and which
/// card the money is going to. Paged rather than scrolled so each answer gets read
/// instead of skimmed.
struct BriefingView: View {
    let dependencies: AppDependencies
    /// Shown as the closing handover after setup, where it ends with a commitment
    /// rather than a dismissal.
    var isHandover: Bool = false
    let onFinish: () -> Void

    @State private var page = 0

    private var briefing: PlanBriefing {
        dependencies.briefingProvider.briefing
    }

    private var presenter: PlanBriefingPresenter {
        dependencies.briefingPresenter
    }

    private var cards: [BriefingItem] {
        [presenter.opening(briefing, planName: dependencies.planStore.activePlan.name)]
            + presenter.items(briefing)
    }

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(Array(cards.enumerated()), id: \.element.id) { index, item in
                    ScrollView {
                        BriefingCard(item: item)
                            .padding(.horizontal, Layout.gutter)
                            .padding(.top, DesignSystem.Space.xxl)
                    }
                    .scrollBounceBehavior(.basedOnSize)
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(DesignSystem.Motion.swap, value: page)

            footer
        }
        .background(Palette.canvas)
    }

    private var footer: some View {
        VStack(spacing: Layout.gap) {
            PageDots(count: cards.count, current: page)

            Button(isLastCard ? closingTitle : "Siguiente") {
                if isLastCard {
                    onFinish()
                } else {
                    page += 1
                }
            }
            .primaryButton()

            // A way out for somebody who has read enough, but not on the last card
            // where it would sit next to a button that does the same thing.
            if !isLastCard {
                Button("Saltar", action: onFinish)
                    .quietButton()
            }
        }
        .padding(Layout.gutter)
    }

    private var isLastCard: Bool { page >= cards.count - 1 }

    private var closingTitle: String {
        isHandover ? "Entendido, empecemos" : "Listo"
    }
}

/// Where you are in the briefing. Its own view because the paging control iOS draws by
/// default cannot be tinted to match a monochrome interface.
private struct PageDots: View {
    let count: Int
    let current: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index == current ? Palette.accent : Palette.surfaceSunken)
                    .frame(width: index == current ? 18 : 6, height: 6)
            }
        }
        .animation(DesignSystem.Motion.swap, value: current)
        .accessibilityHidden(true)
    }
}
