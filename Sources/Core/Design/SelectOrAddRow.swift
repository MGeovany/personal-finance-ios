import SwiftUI

/// Names a value, shows the current answer, and opens a list to change it. When the
/// list does not have what the user needs, the same drawer lets them write it in.
///
/// `SelectRow` covers a closed set the app defines, like a currency. This covers an
/// open one: the app knows the common answers, the user may carry a different one,
/// and neither case should feel like the exception. Picking stays one tap, and typing
/// is there without being the first thing offered.
struct SelectOrAddRow: View {
    let title: String
    @Binding var value: String
    let options: [String]
    /// Shown while there is no answer yet.
    var placeholder: String = "Seleccionar"
    /// Wording of the escape hatch. Reads better named after the thing being added.
    var addTitle: String = "Agregar otro"
    /// Label of the field behind that escape hatch. Defaults to the row's own title.
    var addFieldTitle: String?
    var addPlaceholder: String = ""

    @State private var isPresented = false

    var body: some View {
        Button {
            isPresented = true
        } label: {
            HStack(spacing: Layout.gap) {
                Text(title).fieldLabel()

                Spacer(minLength: DesignSystem.Space.s)

                Text(hasValue ? value : placeholder)
                    .font(Typography.bodyStrong)
                    .foregroundStyle(hasValue ? Palette.primaryText : Palette.tertiaryText)
                    .multilineTextAlignment(.trailing)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Palette.tertiaryText)
            }
            .frame(minHeight: Layout.minimumTouch)
        }
        .buttonStyle(.plain)
        .animation(DesignSystem.Motion.swap, value: value)
        .drawer(isPresented: $isPresented) {
            SelectOrAddDrawer(
                title: title,
                value: $value,
                options: options,
                addTitle: addTitle,
                addFieldTitle: addFieldTitle ?? title,
                addPlaceholder: addPlaceholder
            )
        }
    }

    private var hasValue: Bool {
        !value.trimmingCharacters(in: .whitespaces).isEmpty
    }
}

/// The two states of the drawer: choosing from the list, or writing a new answer.
///
/// Split out so it can hold its own `dismiss` and its own typing state, which must
/// not survive the drawer being closed and opened again.
private struct SelectOrAddDrawer: View {
    let title: String
    @Binding var value: String
    let options: [String]
    let addTitle: String
    let addFieldTitle: String
    let addPlaceholder: String

    @Environment(\.dismiss) private var dismiss
    @State private var isAdding = false
    @State private var typed = ""

    var body: some View {
        Drawer(
            title: isAdding ? addFieldTitle : title,
            cancelTitle: isAdding ? nil : "Cancelar"
        ) {
            if isAdding {
                addingFields
            } else {
                list
            }
        }
        .animation(DesignSystem.Motion.swap, value: isAdding)
    }

    @ViewBuilder
    private var list: some View {
        CardContainer(padding: DesignSystem.Space.xs) {
            VStack(spacing: 0) {
                ForEach(Array(listedOptions.enumerated()), id: \.element) { index, option in
                    if index > 0 { RowDivider() }
                    OptionRow(
                        title: option,
                        isSelected: option.caseInsensitiveCompare(value) == .orderedSame
                    ) {
                        value = option
                        dismiss()
                    }
                }

                // Last, because it is the answer for when none of the others fit.
                if !listedOptions.isEmpty { RowDivider() }
                OptionRow(title: addTitle, icon: "plus") {
                    typed = isCustomValue ? value : ""
                    isAdding = true
                }
            }
        }
    }

    @ViewBuilder
    private var addingFields: some View {
        Group {
            CeroTextField(
                title: addFieldTitle,
                text: $typed,
                placeholder: addPlaceholder,
                capitalization: .words
            )

            Button("Guardar") {
                value = typed.trimmingCharacters(in: .whitespaces)
                dismiss()
            }
            .primaryButton(isEnabled: canSave)
            .disabled(!canSave)

            Button("Volver a la lista") { isAdding = false }
                .quietButton()
        }
    }

    /// A value the user typed belongs in the list, so coming back to this drawer
    /// shows their own answer as the current one instead of losing it.
    private var listedOptions: [String] {
        isCustomValue ? [value] + options : options
    }

    private var isCustomValue: Bool {
        let trimmed = value.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return false }
        return !options.contains { $0.caseInsensitiveCompare(trimmed) == .orderedSame }
    }

    private var canSave: Bool {
        !typed.trimmingCharacters(in: .whitespaces).isEmpty
    }
}
