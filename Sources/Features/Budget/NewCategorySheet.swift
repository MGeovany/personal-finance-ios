import SwiftUI

/// Creates a custom category.
///
/// The flexibility choice is the important field: it tells the engine how hard the
/// category may be cut, so the sheet explains it rather than hiding it.
struct NewCategorySheet: View {
    let currency: CurrencyCode
    let onSave: (String, String, CategoryFlexibility, Money) -> Void

    @State private var name = ""
    @State private var icon = "tag"
    @State private var flexibility: CategoryFlexibility = .discretionary
    @State private var baseline: Money = 0
    @Environment(\.dismiss) private var dismiss

    private let icons = ["tag", "cart", "car", "house", "heart", "book", "gift", "pawprint", "wrench", "airplane", "gamecontroller", "cup.and.saucer"]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Nombre", text: $name)
                    MoneyField(title: "Presupuesto mensual aproximado", amount: $baseline, currency: currency)
                }

                Section("Icono") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: Layout.gap) {
                        ForEach(icons, id: \.self) { candidate in
                            Button {
                                icon = candidate
                            } label: {
                                Image(systemName: candidate)
                                    .font(.system(size: 18))
                                    .foregroundStyle(icon == candidate ? .white : Palette.secondaryText)
                                    .frame(width: 40, height: 40)
                                    .background(
                                        icon == candidate ? Palette.accent : Palette.surfaceMuted,
                                        in: RoundedRectangle(cornerRadius: Layout.chipRadius)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, Layout.tightGap)
                }

                Section {
                    Picker("Tipo", selection: $flexibility) {
                        ForEach([CategoryFlexibility.essential, .discretionary], id: \.self) { option in
                            Text(option.label).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("¿Qué tan flexible es?")
                } footer: {
                    Text(
                        flexibility == .essential
                            ? "Los planes rápidos casi no la recortan. Úsalo para lo que necesitas para funcionar."
                            : "Los planes rápidos la recortan bastante. Úsalo para gustos y entretenimiento."
                    )
                }
            }
            .navigationTitle("Nueva categoría")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Crear") {
                        onSave(name, icon, flexibility, baseline)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
