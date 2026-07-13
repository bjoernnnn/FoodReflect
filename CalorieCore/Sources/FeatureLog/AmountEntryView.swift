import DesignSystem
import Domain
import SwiftUI

/// Mengeneingabe: Gramm-Eingabe + Portions-Shortcuts, Live-Vorschau der kcal/Makros.
struct AmountEntryView: View {
    let food: Food
    let diaryRepository: any DiaryRepository
    let foodCatalogRepository: any FoodCatalogRepository
    let onSaved: () -> Void

    @State private var amountText: String
    @State private var isSaving = false
    @State private var errorMessage: String?

    private let logFood = LogFoodUseCase()

    init(
        food: Food,
        diaryRepository: any DiaryRepository,
        foodCatalogRepository: any FoodCatalogRepository,
        onSaved: @escaping () -> Void
    ) {
        self.food = food
        self.diaryRepository = diaryRepository
        self.foodCatalogRepository = foodCatalogRepository
        self.onSaved = onSaved
        _amountText = State(initialValue: food.servingSizeGrams.map { String(Int($0)) } ?? "100")
    }

    private var amount: Double {
        Double(amountText) ?? 0
    }

    private var preview: DiaryEntry? {
        try? logFood(food: food, amountGrams: amount)
    }

    private var shortcutAmounts: [Double] {
        var values: [Double] = [50, 100, 150, 200]
        if let serving = food.servingSizeGrams, !values.contains(serving) {
            values.insert(serving, at: 0)
        }
        return values
    }

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(food.name).font(TypographyToken.headline)
                    if let brand = food.brand {
                        Text(brand).font(TypographyToken.caption).foregroundStyle(ColorToken.secondaryText)
                    }
                }

                HStack {
                    TextField("Menge", text: $amountText)
                        .keyboardType(.numberPad)
                    Text("g")
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.sm) {
                        ForEach(shortcutAmounts, id: \.self) { value in
                            Button("\(Int(value)) g") { amountText = String(Int(value)) }
                                .buttonStyle(.bordered)
                        }
                    }
                }
            }

            if let preview {
                Section("Vorschau") {
                    LabeledContent("kcal", value: "\(Int(preview.kcal))")
                    LabeledContent("Protein", value: String(format: "%.1f g", preview.protein))
                    LabeledContent("Kohlenhydrate", value: String(format: "%.1f g", preview.carbs))
                    LabeledContent("Fett", value: String(format: "%.1f g", preview.fat))
                }
            }

            if let errorMessage {
                Text(errorMessage).foregroundStyle(ColorToken.warning)
            }

            Button {
                Task { await save() }
            } label: {
                if isSaving {
                    ProgressView()
                } else {
                    Text("Speichern")
                }
            }
            .disabled(isSaving || amount <= 0)
        }
        .navigationTitle("Menge")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func save() async {
        guard let entry = try? logFood(food: food, amountGrams: amount) else {
            errorMessage = "Ungültige Menge."
            return
        }
        isSaving = true
        errorMessage = nil
        do {
            try await diaryRepository.save(entry)
            try? await foodCatalogRepository.recordUsage(foodID: food.id, at: entry.consumedAt)
            onSaved()
        } catch {
            errorMessage = "Speichern fehlgeschlagen. Bitte erneut versuchen."
        }
        isSaving = false
    }
}
