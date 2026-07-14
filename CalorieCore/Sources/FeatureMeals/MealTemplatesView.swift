import DesignSystem
import Domain
import SwiftUI

/// Gerichte-Verwaltung: Liste aller Gerichte mit Anlegen/Bearbeiten/Löschen.
/// Wird als eigener Screen aus den Einstellungen erreicht.
public struct MealTemplatesView: View {
    @State private var viewModel: MealTemplatesViewModel
    @State private var editorTarget: EditorTarget?

    private let mealTemplateRepository: any MealTemplateRepository
    private let foodCatalogRepository: any FoodCatalogRepository
    private let foodDataSource: any FoodDataSource

    private enum EditorTarget: Identifiable {
        case new
        case edit(MealTemplate)
        var id: String {
            switch self {
            case .new: "new"
            case let .edit(template): template.id.uuidString
            }
        }
    }

    public init(
        mealTemplateRepository: any MealTemplateRepository,
        foodCatalogRepository: any FoodCatalogRepository,
        foodDataSource: any FoodDataSource
    ) {
        self.mealTemplateRepository = mealTemplateRepository
        self.foodCatalogRepository = foodCatalogRepository
        self.foodDataSource = foodDataSource
        _viewModel = State(initialValue: MealTemplatesViewModel(repository: mealTemplateRepository))
    }

    public var body: some View {
        content
            .navigationTitle("Gerichte")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        editorTarget = .new
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Gericht anlegen")
                    .accessibilityIdentifier("meals.addButton")
                }
            }
            .task { await viewModel.load() }
            .sheet(item: $editorTarget) { target in
                NavigationStack {
                    MealEditorView(viewModel: makeEditor(for: target)) {
                        editorTarget = nil
                        Task { await viewModel.load() }
                    }
                }
            }
    }

    private func makeEditor(for target: EditorTarget) -> MealEditorViewModel {
        let existing: MealTemplate? = if case let .edit(template) = target {
            template
        } else {
            nil
        }
        return MealEditorViewModel(
            existing: existing,
            repository: mealTemplateRepository,
            foodCatalogRepository: foodCatalogRepository,
            foodDataSource: foodDataSource
        )
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView()
        case .empty:
            ContentUnavailableView {
                Label("Keine Gerichte", systemImage: "fork.knife")
            } description: {
                Text("Lege ein Gericht an, um mehrere Lebensmittel mit einem Tipp zu loggen.")
            } actions: {
                Button("Gericht anlegen") { editorTarget = .new }
            }
        case let .error(message):
            ContentUnavailableView {
                Label("Fehler", systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
            } actions: {
                Button("Erneut versuchen") { Task { await viewModel.load() } }
            }
        case let .loaded(templates):
            List {
                ForEach(templates) { template in
                    Button {
                        editorTarget = .edit(template)
                    } label: {
                        row(template)
                    }
                    .buttonStyle(.plain)
                    .swipeActions {
                        Button("Löschen", role: .destructive) {
                            Task { await viewModel.delete(id: template.id) }
                        }
                    }
                }
            }
        }
    }

    private func row(_ template: MealTemplate) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(template.name).font(TypographyToken.body)
                Text("\(template.items.count) Zutaten")
                    .font(TypographyToken.caption)
                    .foregroundStyle(ColorToken.secondaryText)
            }
            Spacer()
            Text("\(Int(template.totalKcal)) kcal")
                .font(TypographyToken.body)
                .foregroundStyle(ColorToken.secondaryText)
        }
    }
}
