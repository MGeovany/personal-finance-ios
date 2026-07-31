import SwiftUI

/// The first thing asked, and the only free-text answer in the flow.
///
/// One field, focused on arrival, so the keyboard is already up and the user types
/// four letters and moves on.
struct OnboardingNameStep: View {
    @Bindable var model: OnboardingViewModel

    @FocusState private var isFocused: Bool

    var body: some View {
        ChoiceStack {
            CardContainer {
                TextField("Tu nombre", text: $model.draft.name)
                    .font(Typography.display(24, .displaySemibold))
                    .foregroundStyle(Palette.primaryText)
                    .textInputAutocapitalization(.words)
                    .textContentType(.givenName)
                    .submitLabel(.continue)
                    .focused($isFocused)
                    .onSubmit {
                        guard model.canAdvance else { return }
                        model.advance()
                    }
                    .fieldWell(isFocused: isFocused, height: 64)
            }
        }
        .onAppear {
            // A beat after the slide, or the keyboard fights the transition.
            Task {
                try? await Task.sleep(for: .milliseconds(360))
                isFocused = true
            }
        }
    }
}
