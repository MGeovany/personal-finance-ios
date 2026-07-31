import SwiftUI

/// The well every input sits in: a shade below the card, with the accent border
/// appearing only while the field has focus.
struct FieldWell: ViewModifier {
    var isFocused: Bool = false
    var height: CGFloat = Layout.controlHeight

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: Layout.fieldRadius, style: .continuous)
        content
            .padding(.horizontal, Layout.cardPadding)
            .frame(height: height)
            .background(Palette.surfaceSunken.opacity(0.85), in: shape)
            .overlay {
                shape.strokeBorder(isFocused ? Palette.accent : Color.white.opacity(0.55), lineWidth: isFocused ? 1.5 : 1)
            }
            .animation(DesignSystem.Motion.tap, value: isFocused)
    }
}

extension View {
    func fieldWell(isFocused: Bool = false, height: CGFloat = Layout.controlHeight) -> some View {
        modifier(FieldWell(isFocused: isFocused, height: height))
    }

    /// The label that names a field or a row.
    func fieldLabel() -> some View {
        font(Typography.label).foregroundStyle(Palette.secondaryText)
    }
}

/// A labelled text input.
struct CeroTextField: View {
    let title: String
    @Binding var text: String
    var placeholder: String = ""
    var capitalization: TextInputAutocapitalization = .sentences

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Space.s) {
            Text(title).fieldLabel()

            TextField(placeholder.isEmpty ? title : placeholder, text: $text)
                .font(Typography.bodyStrong)
                .foregroundStyle(Palette.primaryText)
                .textInputAutocapitalization(capitalization)
                .focused($isFocused)
                .fieldWell(isFocused: isFocused)
        }
    }
}

/// Percentage input, kept separate because a rate is not money and should not
/// carry a currency symbol.
struct PercentField: View {
    let title: String
    @Binding var percent: Double
    var caption: String? = nil

    @State private var text: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Space.s) {
            Text(title).fieldLabel()

            HStack {
                TextField("0", text: $text)
                    .font(Typography.amount)
                    .foregroundStyle(Palette.primaryText)
                    .keyboardType(.decimalPad)
                    .focused($isFocused)
                    .onChange(of: text) { _, newValue in
                        percent = parse(newValue)
                    }
                Text("%")
                    .font(Typography.amount)
                    .foregroundStyle(Palette.tertiaryText)
            }
            .fieldWell(isFocused: isFocused)

            if let caption {
                Text(caption)
                    .font(Typography.caption)
                    .foregroundStyle(Palette.tertiaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .onAppear { show(percent) }
        .onChange(of: percent) { _, newValue in
            // Only when the value changed from outside, so a field being typed into
            // is never rewritten under the user. Lets a caller fill the rate in from
            // an estimate and have it appear.
            guard parse(text) != newValue else { return }
            show(newValue)
        }
    }

    private func show(_ value: Double) {
        text = value > 0 ? trimmed(value) : ""
    }

    private func parse(_ input: String) -> Double {
        Double(input.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    private func trimmed(_ value: Double) -> String {
        value == value.rounded() ? String(Int(value)) : String(value)
    }
}

/// A yes-or-no setting, with room for the sentence that explains it.
struct CeroToggle: View {
    let title: String
    var caption: String?
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Typography.bodyStrong)
                    .foregroundStyle(Palette.primaryText)
                if let caption {
                    Text(caption)
                        .font(Typography.caption)
                        .foregroundStyle(Palette.tertiaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .tint(Palette.accent)
    }
}

/// One choice in a list of them: a row-shaped button that shows whether it is the
/// current answer.
///
/// A flat list row: icon, label, optional check. No per-option cards; the drawer
/// or parent card supplies the surface.
struct OptionRow: View {
    let title: String
    var detail: String?
    var icon: String?
    var isSelected: Bool = false
    var isDestructive: Bool = false
    /// Kept for call sites; rows are always flat now.
    var isElevated: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Space.m) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(isDestructive ? Palette.critical : Palette.secondaryText)
                        .frame(width: 24)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Typography.body)
                        .foregroundStyle(isDestructive ? Palette.critical : Palette.primaryText)
                        .multilineTextAlignment(.leading)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                    if let detail {
                        Text(detail)
                            .font(Typography.caption)
                            .foregroundStyle(isDestructive ? Palette.critical.opacity(0.7) : Palette.tertiaryText)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                            .minimumScaleFactor(0.85)
                    }
                }

                Spacer(minLength: DesignSystem.Space.s)

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Palette.primaryText)
                }
            }
            .padding(.horizontal, DesignSystem.Space.s)
            .padding(.vertical, DesignSystem.Space.m)
            .frame(minHeight: Layout.minimumTouch)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// Names a setting, shows its current answer, and opens a drawer to change it.
///
/// This replaces the system's navigation-link picker, which needed a `Form` and a
/// pushed screen to change one value. A drawer answers it in place.
struct SelectRow<Value: Hashable>: View {
    let title: String
    @Binding var selection: Value
    let options: [Value]
    let label: (Value) -> String
    var icon: ((Value) -> String?)?
    var detail: ((Value) -> String?)?

    @State private var isPickerPresented = false

    var body: some View {
        Button {
            isPickerPresented = true
        } label: {
            HStack(spacing: Layout.gap) {
                Text(title).fieldLabel()

                Spacer(minLength: DesignSystem.Space.s)

                if let glyph = icon?(selection) {
                    Image(systemName: glyph)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Palette.primaryText)
                }

                Text(label(selection))
                    .font(Typography.bodyStrong)
                    .foregroundStyle(Palette.primaryText)
                    .contentTransition(.numericText())

                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Palette.tertiaryText)
            }
            .frame(minHeight: Layout.minimumTouch)
        }
        .buttonStyle(.plain)
        .animation(DesignSystem.Motion.swap, value: selection)
        .drawer(isPresented: $isPickerPresented) {
            Drawer(title: title, cancelTitle: "Cancelar") {
                CardContainer(padding: DesignSystem.Space.xs) {
                    VStack(spacing: 0) {
                        ForEach(Array(options.enumerated()), id: \.element) { index, option in
                            if index > 0 { RowDivider() }
                            OptionRow(
                                title: label(option),
                                detail: detail?(option),
                                icon: icon?(option),
                                isSelected: option == selection
                            ) {
                                selection = option
                                isPickerPresented = false
                            }
                        }
                    }
                }
            }
        }
    }
}

/// Two or three choices shown side by side, for answers short enough to compare at
/// a glance.
struct SegmentedSelector<Value: Hashable>: View {
    @Binding var selection: Value
    let options: [Value]
    let label: (Value) -> String

    @Namespace private var indicator

    var body: some View {
        HStack(spacing: DesignSystem.Space.xxs) {
            ForEach(options, id: \.self) { option in
                let isSelected = option == selection

                Button {
                    withAnimation(DesignSystem.Motion.swap) { selection = option }
                } label: {
                    Text(label(option))
                        .font(Typography.label)
                        .foregroundStyle(isSelected ? Palette.invertedText : Palette.secondaryText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background {
                            if isSelected {
                                Capsule()
                                    .fill(Palette.accent)
                                    .matchedGeometryEffect(id: "segment", in: indicator)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? [.isSelected] : [])
            }
        }
        .padding(DesignSystem.Space.xxs)
        .modifier(SegmentGlassWell())
        .sensoryFeedback(.selection, trigger: selection)
    }
}

private struct SegmentGlassWell: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content.glassEffect(.regular, in: Capsule())
        } else {
            content.background(Palette.surfaceSunken, in: Capsule())
        }
    }
}

/// A date, changed in a drawer so the calendar does not push the rest of the modal
/// around when it opens.
struct DateRow: View {
    let title: String
    @Binding var date: Date
    var range: PartialRangeFrom<Date>?

    @Environment(\.planDates) private var dates
    @State private var isPresented = false

    var body: some View {
        Button {
            isPresented = true
        } label: {
            HStack {
                Text(title).fieldLabel()
                Spacer(minLength: DesignSystem.Space.s)
                Text(dates.full(date))
                    .font(Typography.bodyStrong)
                    .foregroundStyle(Palette.primaryText)
                Image(systemName: "calendar")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Palette.tertiaryText)
            }
            .frame(minHeight: Layout.minimumTouch)
        }
        .buttonStyle(.plain)
        .drawer(isPresented: $isPresented) {
            Drawer(title: title) {
                Group {
                    if let range {
                        DatePicker(title, selection: $date, in: range, displayedComponents: .date)
                    } else {
                        DatePicker(title, selection: $date, displayedComponents: .date)
                    }
                }
                .datePickerStyle(.graphical)
                .labelsHidden()
                .tint(Palette.accent)

                Button("Listo") { isPresented = false }
                    .primaryButton()
            }
        }
    }
}

/// A date that may not exist yet.
///
/// `DateRow` always holds one, which is right for a deadline the user is choosing.
/// This is for the dates that are genuinely optional: a trip somebody wants to take
/// without knowing when. It reads as unanswered until it is answered, rather than
/// defaulting to today and quietly claiming a day the user never picked.
struct OptionalDateRow: View {
    let title: String
    @Binding var date: Date?
    var placeholder: String = "Sin fecha"
    /// The day the picker opens on when there is no answer yet. A goal is in the
    /// future, so today is a poor place to start.
    var suggestion: Date = Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date()

    @Environment(\.planDates) private var dates
    @State private var isPresented = false

    var body: some View {
        Button {
            isPresented = true
        } label: {
            HStack {
                Text(title).fieldLabel()
                Spacer(minLength: DesignSystem.Space.s)
                Text(date.map(dates.full) ?? placeholder)
                    .font(Typography.bodyStrong)
                    .foregroundStyle(date == nil ? Palette.tertiaryText : Palette.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                Image(systemName: "calendar")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Palette.tertiaryText)
            }
            .frame(minHeight: Layout.minimumTouch)
        }
        .buttonStyle(.plain)
        .drawer(isPresented: $isPresented) {
            Drawer(title: title) {
                DatePicker(
                    title,
                    selection: Binding(
                        get: { date ?? suggestion },
                        set: { date = $0 }
                    ),
                    in: Date()...,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .labelsHidden()
                .tint(Palette.accent)

                Button("Listo") { isPresented = false }
                    .primaryButton()

                if date != nil {
                    Button("Quitar fecha") {
                        date = nil
                        isPresented = false
                    }
                    .quietButton()
                }
            }
        }
    }
}

/// A time of day, changed in a drawer for the same reason `DateRow` is.
struct TimeRow: View {
    let title: String
    @Binding var time: Date

    @State private var isPresented = false

    var body: some View {
        Button {
            isPresented = true
        } label: {
            HStack {
                Text(title).fieldLabel()
                Spacer(minLength: DesignSystem.Space.s)
                Text(time, format: .dateTime.hour().minute())
                    .font(Typography.bodyStrong)
                    .foregroundStyle(Palette.primaryText)
                Image(systemName: "clock")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Palette.tertiaryText)
            }
            .frame(minHeight: Layout.minimumTouch)
        }
        .buttonStyle(.plain)
        .drawer(isPresented: $isPresented) {
            Drawer(title: title) {
                DatePicker(title, selection: $time, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()

                Button("Listo") { isPresented = false }
                    .primaryButton()
            }
        }
    }
}

/// The row that leads somewhere else: a name, what it currently says, and the
/// chevron that promises a screen behind it.
///
/// Used as the label of a `NavigationLink`, so it replaces the system row without
/// needing a `List` to draw it.
struct NavRow: View {
    let title: String
    var value: String?
    var icon: String?

    var body: some View {
        HStack(spacing: Layout.gap) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Palette.primaryText)
                    .frame(width: 22)
            }

            Text(title)
                .font(Typography.bodyStrong)
                .foregroundStyle(Palette.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Spacer(minLength: DesignSystem.Space.s)

            if let value {
                Text(value)
                    .font(Typography.body)
                    .foregroundStyle(Palette.secondaryText)
                    .multilineTextAlignment(.trailing)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                    .layoutPriority(1)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Palette.tertiaryText)
        }
        .frame(minHeight: Layout.minimumTouch)
        .contentShape(.rect)
    }
}

/// Day-of-month selection that allows "not set", since not every charge has a
/// fixed day.
struct DayOfMonthPicker: View {
    let title: String
    @Binding var day: Int?

    var body: some View {
        SelectRow(
            title: title,
            selection: Binding(
                get: { day ?? 0 },
                set: { day = $0 == 0 ? nil : $0 }
            ),
            options: Array(0...31),
            label: { $0 == 0 ? "Sin definir" : "Día \($0)" }
        )
    }
}
