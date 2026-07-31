import SwiftUI

/// Whether the app should ask, each day, what was spent.
///
/// The plan only stays true if expenses get logged, and the reminder is what makes
/// that happen. Asked here rather than buried in settings, and offered as moments in
/// the day rather than a clock: people know when they check their phone, not which
/// hour they want an alarm at.
struct OnboardingRemindersStep: View {
    @Bindable var model: OnboardingViewModel

    var body: some View {
        ChoiceStack {
            ForEach(ReminderMoment.allCases) { moment in
                ChoiceCard(
                    title: moment.label,
                    detail: moment.detail,
                    icon: moment.icon,
                    isSelected: model.draft.remindersEnabled && model.draft.reminderHour == moment.hour
                ) {
                    model.draft.remindersEnabled = true
                    model.draft.reminderHour = moment.hour
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
