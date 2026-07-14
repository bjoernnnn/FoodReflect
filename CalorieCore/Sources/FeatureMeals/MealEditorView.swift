import DesignSystem
import Domain
import SwiftUI

/// Gericht erstellen/bearbeiten: Name, optionaler Mahlzeitentyp, Zutatenliste mit Live-Summe.
struct MealEditorView: View {
    @State private var viewModel: MealEditorViewModel
    @State private var isShowingAddFood = false
    private let onSaved: () -> Void

    init(viewModel: MealEditorViewModel, onSaved: @escaping () -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onSaved = onSaved
    }

    var body: some View {
        Form {
            Section("Name") {
                TextField("z. B. Standard-Frühstück", text: $viewModel.name)
                    .accessibilityIdentifier("mealEditor.nameField")
            }

            Section("Mahlzeit (optional)") {
                Picker("Mahlzeit", selection: $viewModel.mealType) {
                    Text("Automatisch").tag(MealType?.none)
                    ForEach(MealType.allCases) { meal in
                        Text(meal.displayName).tag(MealType?.some(meal))
                    }
                }
            }

            Section {
                if viewModel.items.isEmpty {
                    Text("Noch keine Zutaten – füge Lebensmittel hinzu.")
                        .font(TypographyToken.caption)
                        .foregroundStyle(ColorToken.secondaryText)
                } else {
                    ForEach(viewModel.items) { item in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(item.foodName).font(TypographyToken.body)
                                Text("\(Int(item.amountGrams)) g")
                                    .font(TypographyToken.caption)
                                    .foregroundStyle(ColorToken.secondaryText)
                            }
                            Spacer()
                            Text("\(Int(item.kcal)) kcal").font(TypographyToken.body)
                        }
                    }
                    .onDelete { viewModel.removeItems(at: $0) }
                }
                Button("Lebensmittel hinzufügen") { isShowingAddFood = true }
                    .accessibilityIdentifier("mealEditor.addFoodButton")
            } header: {
                Text("Zutaten")
            } footer: {
                if !viewModel.items.isEmpty {
                    Text(
                        "Summe: \(Int(viewModel.totalKcal)) kcal · " +
                            "\(Int(viewModel.totalProtein)) P / \(Int(viewModel.totalCarbs)) K / \(Int(viewModel.totalFat)) F"
                    )
                    .font(TypographyToken.caption)
                }
            }
        }
        .navigationTitle("Gericht")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Speichern") {
                    Task {
                        if await viewModel.save() {
                            onSaved()
                        }
                    }
                }
                .disabled(!viewModel.canSave || viewModel.isSaving)
                .accessibilityIdentifier("mealEditor.saveButton")
            }
        }
        .sheet(isPresented: $isShowingAddFood) {
            AddFoodSheet(provider: viewModel) { food, amount in
                viewModel.addFood(food, amountGrams: amount)
            }
        }
    }
}
