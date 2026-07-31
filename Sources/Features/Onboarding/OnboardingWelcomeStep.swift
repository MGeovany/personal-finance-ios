import SwiftUI

/// The opening screen: brand, one line, and room to breathe.
///
/// Setup used to open with a checklist of promises inside a card. That reads as a
/// feature tour. A first screen only needs the name, what the app is for, and the
/// button that starts. Anything else waits until it is asked.
struct OnboardingWelcomeStep: View {
    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer(minLength: DesignSystem.Space.xxxl)

            Text("Cero")
                .font(Typography.display(72, .displayRegular))
                .foregroundStyle(Palette.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)

            Text("Tu plan para llegar a cero deudas.")
                .font(Typography.display(36, .displaySemibold))
                .foregroundStyle(Palette.primaryText)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, DesignSystem.Space.xl)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)

            Text("Ingreso, gastos y deudas, claros en unos minutos.")
                .font(Typography.text(24, .light))
                .foregroundStyle(Palette.tertiaryText)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, DesignSystem.Space.l)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 8)

            Spacer(minLength: DesignSystem.Space.xxxl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .onAppear {
            withAnimation(DesignSystem.Motion.present.delay(0.08)) {
                appeared = true
            }
        }
    }
}
