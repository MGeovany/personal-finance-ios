import SwiftUI

/// Whether the app should ask, each night, what was spent.
///
/// The plan only stays true if expenses get logged, and the reminder is what makes
/// that happen. Asked here rather than buried in settings, and with the hour offered
/// as three choices so answering it takes one tap.
struct OnboardingRemindersStep: View {
    @Bindable var model: OnboardingViewModel

    private let hours = [
        (hour: 20, label: "En la noche", detail: "8:00 PM"),
        (hour: 21, label: "Antes de dormir", detail: "9:00 PM"),
        (hour: 22, label: "Ya acostado", detail: "10:00 PM"),
    ]

    var body: some View {
        ChoiceStack {
            ForEach(hours, id: \.hour) { option in
                ChoiceCard(
                    title: option.label,
                    detail: option.detail,
                    icon: "bell",
                    isSelected: model.draft.remindersEnabled && model.draft.reminderHour == option.hour
                ) {
                    model.draft.remindersEnabled = true
                    model.draft.reminderHour = option.hour
                    model.advanceAfterAnswer()
                }
            }

            ChoiceCard(
                title: "No me recuerdes",
                detail: "Puedes activarlo después en Ajustes.",
                icon: "bell.slash",
                isSelected: !model.draft.remindersEnabled
            ) {
                model.draft.remindersEnabled = false
                model.advanceAfterAnswer()
            }
            .padding(.top, Layout.tightGap)
        }
    }
}
