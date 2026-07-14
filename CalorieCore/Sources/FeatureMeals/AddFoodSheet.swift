import DesignSystem
import Domain
import SwiftUI

/// Gemeinsame Fähigkeit von Gericht- und Schnellauswahl-Editor: Lebensmittel suchen.
@MainActor
public protocol FoodSearchProviding {
    var searchState: ViewState<[Food]> { get }
    func search(query: String) async
}

/// Sheet zum Suchen eines Lebensmittels und Wählen der Menge – liefert (Food, Gramm) zurück.
/// Generisch über den konkreten `@Observable`-Provider, damit die Beobachtung von `searchState` greift.
struct AddFoodSheet<Provider: FoodSearchProviding & AnyObject>: View {
    let provider: Provider
    let onPick: (Food, Double) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var pendingFood: Food?
    @State private var amountText = "100"

    var body: some View {
        NavigationStack {
            Group {
                if let pendingFood {
                    amountStep(for: pendingFood)
                } else {
                    searchStep
                }
            }
            .navigationTitle(pendingFood == nil ? "Lebensmittel" : "Menge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
            }
            .task(id: query) {
                try? await Task.sleep(nanoseconds: 300_000_000)
                guard !Task.isCancelled else { return }
                await provider.search(query: query)
            }
        }
    }

    private var searchStep: some View {
        VStack(spacing: 0) {
            TextField("Suchen…", text: $query)
                .textFieldStyle(.roundedBorder)
                .padding(Spacing.md)
            results
        }
    }

    @ViewBuilder
    private var results: some View {
        switch provider.searchState {
        case .empty:
            ContentUnavailableView("Lebensmittel suchen", systemImage: "magnifyingglass")
        case .loading:
            ProgressView().frame(maxHeight: .infinity)
        case .error:
            ContentUnavailableView("Keine Verbindung", systemImage: "wifi.slash")
        case let .loaded(foods):
            List(foods) { food in
                Button {
                    amountText = food.servingSizeGrams.map { String(Int($0)) } ?? "100"
                    pendingFood = food
                } label: {
                    HStack {
                        Text(food.name).font(TypographyToken.body)
                        Spacer()
                        Text("\(Int(food.kcalPer100g)) kcal/100g")
                            .font(TypographyToken.caption)
                            .foregroundStyle(ColorToken.secondaryText)
                    }
                }
                .buttonStyle(.plain)
            }
            .listStyle(.plain)
        }
    }

    private func amountStep(for food: Food) -> some View {
        Form {
            Section(food.name) {
                HStack {
                    TextField("Menge", text: $amountText)
                        .keyboardType(.numberPad)
                    Text("g")
                }
            }
            Button("Hinzufügen") {
                if let amount = Double(amountText), amount > 0 {
                    onPick(food, amount)
                    dismiss()
                }
            }
            .disabled((Double(amountText) ?? 0) <= 0)
        }
    }
}
