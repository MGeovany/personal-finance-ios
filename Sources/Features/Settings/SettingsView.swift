import SwiftUI

/// Everything that is not a daily action: the plan, the money that never changes,
/// the reminders, and the way into the simulator and the closes.
struct SettingsView: View {
    let dependencies: AppDependencies

    @State private var showsWeeklyClose = false
    @State private var showsMonthlyClose = false
    @State private var renamingSpeed: PlanSpeed?

    private var profile: ProfileEntity { dependencies.profile }
    private var planStore: PlanStore { dependencies.planStore }

    var body: some View {
        List {
            planSection
            toolsSection
            moneySection
            catalogSection
            remindersSection
            closesSection
        }
        .navigationTitle("Ajustes")
        .sheet(isPresented: $showsWeeklyClose) {
            WeeklyCloseSheet(dependencies: dependencies)
        }
        .sheet(isPresented: $showsMonthlyClose) {
            MonthlyCloseSheet(dependencies: dependencies)
        }
        .sheet(item: $renamingSpeed) { speed in
            RenamePlanSheet(
                speed: speed,
                currentName: profile.name(for: speed)
            ) { newName in
                dependencies.preferences.rename(speed: speed, to: newName)
            }
        }
    }

    // MARK: - Sections

    private var planSection: some View {
        Section("Tu plan") {
            NavigationLink {
                PlanComparisonView(dependencies: dependencies)
            } label: {
                LabeledContent("Plan activo", value: planStore.activePlan.name)
            }

            NavigationLink {
                TargetDateView(dependencies: dependencies)
            } label: {
                LabeledContent(
                    "Fecha objetivo",
                    value: profile.targetDate.map(dependencies.dates.monthAndYear) ?? "Sin definir"
                )
            }

            ForEach(PlanSpeed.displayOrder) { speed in
                Button {
                    renamingSpeed = speed
                } label: {
                    LabeledContent(profile.name(for: speed)) {
                        Text("Renombrar").foregroundStyle(Palette.accent)
                    }
                }
            }
        }
    }

    private var toolsSection: some View {
        Section("Herramientas") {
            NavigationLink {
                SimulatorView(dependencies: dependencies)
            } label: {
                Label("¿Qué pasa si...?", systemImage: "wand.and.stars")
            }
        }
    }

    private var moneySection: some View {
        Section("Tu dinero") {
            LabeledContent(
                "Ingreso mensual",
                value: dependencies.money.string(profile.primaryIncome, currency: profile.currency)
            )
            LabeledContent(
                "Fondo de emergencia",
                value: dependencies.money.string(profile.emergencyFund, currency: profile.currency)
            )
            LabeledContent(
                "Ahorros",
                value: dependencies.money.string(profile.savings, currency: profile.currency)
            )
            NavigationLink {
                MoneyEditorView(dependencies: dependencies)
            } label: {
                Text("Editar montos")
            }
            LabeledContent("Moneda", value: "\(profile.currency.symbol) · \(profile.currency.rawValue)")
        }
    }

    private var catalogSection: some View {
        Section("Compromisos") {
            NavigationLink {
                UtilitiesView(dependencies: dependencies)
            } label: {
                Label("Servicios públicos", systemImage: "bolt")
            }
            NavigationLink {
                SubscriptionsView(dependencies: dependencies)
            } label: {
                Label("Suscripciones", systemImage: "repeat")
            }
            NavigationLink {
                FixedExpensesView(dependencies: dependencies)
            } label: {
                Label("Gastos fijos", systemImage: "house")
            }
        }
    }

    private var remindersSection: some View {
        Section {
            Toggle(
                "Recordatorios",
                isOn: Binding(
                    get: { profile.notificationsEnabled },
                    set: { enabled in
                        dependencies.preferences.setReminder(
                            hour: profile.reminderHour,
                            minute: profile.reminderMinute,
                            enabled: enabled
                        )
                    }
                )
            )

            if profile.notificationsEnabled {
                DatePicker(
                    "Hora del recordatorio",
                    selection: Binding(
                        get: { reminderDate },
                        set: { date in
                            let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
                            dependencies.preferences.setReminder(
                                hour: parts.hour ?? 21,
                                minute: parts.minute ?? 0,
                                enabled: true
                            )
                        }
                    ),
                    displayedComponents: .hourAndMinute
                )
            }
        } header: {
            Text("Recordatorios")
        } footer: {
            Text("Cada noche te preguntamos si ya agregaste tus gastos. También te avisamos de fechas de pago, cortes y cobros próximos.")
        }
    }

    private var closesSection: some View {
        Section("Cierres") {
            Button("Cierre semanal") { showsWeeklyClose = true }
            Button("Cierre mensual") { showsMonthlyClose = true }
        }
    }

    private var reminderDate: Date {
        Calendar.current.date(
            bySettingHour: profile.reminderHour,
            minute: profile.reminderMinute,
            second: 0,
            of: Date()
        ) ?? Date()
    }
}

/// Renames a plan. The three speeds keep their behaviour; only the label changes.
struct RenamePlanSheet: View {
    let speed: PlanSpeed
    let currentName: String
    let onSave: (String) -> Void

    @State private var name: String
    @Environment(\.dismiss) private var dismiss

    init(speed: PlanSpeed, currentName: String, onSave: @escaping (String) -> Void) {
        self.speed = speed
        self.currentName = currentName
        self.onSave = onSave
        self._name = State(initialValue: currentName)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(speed.defaultName, text: $name)
                } footer: {
                    Text(speed.shortDescription)
                }
            }
            .navigationTitle("Renombrar plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        onSave(name)
                        dismiss()
                    }
                }
            }
        }
    }
}
