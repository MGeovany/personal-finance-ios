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
        ModalScaffold(
            title: "Nueva categoría",
            primary: ModalAction("Crear", isEnabled: !name.trimmingCharacters(in: .whitespaces).isEmpty) {
                onSave(name, icon, flexibility, baseline)
                dismiss()
            }
        ) {
            CardSection {
                CeroTextField(title: "Nombre", text: $name, placeholder: "Mascota")
                MoneyField(title: "Presupuesto mensual aproximado", amount: $baseline, currency: currency)
            }

            CardSection(header: "Icono") {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: Layout.gap) {
                    ForEach(icons, id: \.self) { candidate in
                        Button {
                            withAnimation(DesignSystem.Motion.tap) { icon = candidate }
                        } label: {
                            Image(systemName: candidate)
                                .font(.system(size: 18))
                                .foregroundStyle(icon == candidate ? Palette.invertedText : Palette.secondaryText)
                                .frame(width: 44, height: 44)
                                .background(
                                    icon == candidate ? Palette.accent : Palette.surfaceMuted,
                                    in: Circle()
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            CardSection(
                header: "¿Qué tan flexible es?",
                footer: flexibility == .essential
                    ? "Los planes rápidos casi no la recortan. Úsalo para lo que necesitas para funcionar."
                    : "Los planes rápidos la recortan bastante. Úsalo para gustos y entretenimiento."
            ) {
                SegmentedSelector(
                    selection: $flexibility,
                    options: [.essential, .discretionary],
                    label: \.label
                )
            }
        }
        .modalPresentation()
    }
}
