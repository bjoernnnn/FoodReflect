import DesignSystem
import Domain
import SwiftUI

/// Schnellauswahl bearbeiten: dauerhaft aktiver EditMode (Drag&Drop-Sortierung), Ordner (1 Ebene),
/// Hinzufügen von Gerichten/Lebensmitteln. Diese Reihenfolge wird 1:1 zur Watch gespiegelt.
public struct QuickListEditorView: View {
    @State private var viewModel: QuickListEditorViewModel
    @State private var isShowingAddFood = false
    @State private var isShowingNewFolder = false
    @State private var newFolderName = ""

    public init(
        quickListRepository: any QuickListRepository,
        mealTemplateRepository: any MealTemplateRepository,
        foodCatalogRepository: any FoodCatalogRepository,
        foodDataSource: any FoodDataSource
    ) {
        _viewModel = State(initialValue: QuickListEditorViewModel(
            quickListRepository: quickListRepository,
            mealTemplateRepository: mealTemplateRepository,
            foodCatalogRepository: foodCatalogRepository,
            foodDataSource: foodDataSource
        ))
    }

    public var body: some View {
        list
            .navigationTitle("Schnellauswahl")
            .navigationBarTitleDisplayMode(.inline)
            .environment(\.editMode, .constant(.active))
            .toolbar { toolbarMenu }
            .task { await viewModel.load() }
            .sheet(isPresented: $isShowingAddFood) {
                AddFoodSheet(provider: viewModel) { food, amount in
                    Task { await viewModel.addFood(food, amountGrams: amount) }
                }
            }
            .alert("Neuer Ordner", isPresented: $isShowingNewFolder) {
                TextField("Name", text: $newFolderName)
                Button("Anlegen") {
                    Task { await viewModel.createFolder(name: newFolderName); newFolderName = "" }
                }
                Button("Abbrechen", role: .cancel) { newFolderName = "" }
            }
    }

    @ToolbarContentBuilder
    private var toolbarMenu: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Menu("Gericht hinzufügen") {
                    if viewModel.templates.isEmpty {
                        Text("Keine Gerichte angelegt")
                    }
                    ForEach(viewModel.templates) { template in
                        Button(template.name) { Task { await viewModel.addMeal(templateID: template.id) } }
                    }
                }
                Button("Lebensmittel hinzufügen") { isShowingAddFood = true }
                Button("Ordner anlegen") { isShowingNewFolder = true }
            } label: {
                Image(systemName: "plus")
            }
            .accessibilityIdentifier("quicklist.addMenu")
        }
    }

    @ViewBuilder
    private var list: some View {
        if viewModel.isLoaded, viewModel.quickList.entries.isEmpty {
            ContentUnavailableView {
                Label("Schnellauswahl leer", systemImage: "bolt")
            } description: {
                Text("Füge Gerichte und Lebensmittel hinzu – sie erscheinen in dieser Reihenfolge auf der Watch.")
            }
        } else {
            List {
                ForEach(viewModel.quickList.entries) { entry in
                    entryRow(entry)
                }
                .onMove { source, destination in
                    Task { await viewModel.moveTopLevel(from: source, to: destination) }
                }
            }
        }
    }

    @ViewBuilder
    private func entryRow(_ entry: QuickListEntry) -> some View {
        switch entry {
        case let .leaf(leaf):
            leafRow(leaf, inFolder: nil)
        case let .folder(id, name, items):
            Section {
                ForEach(items) { leaf in
                    leafRow(leaf, inFolder: id)
                }
            } header: {
                HStack {
                    Label(name, systemImage: "folder")
                    Spacer()
                    Button("Löschen", role: .destructive) { Task { await viewModel.delete(entryID: id) } }
                        .font(TypographyToken.caption)
                }
            }
        }
    }

    private func leafRow(_ leaf: QuickListLeaf, inFolder folderID: UUID?) -> some View {
        HStack {
            Image(systemName: viewModel.isMeal(leaf) ? "fork.knife" : "leaf")
                .foregroundStyle(ColorToken.accent)
            Text(viewModel.displayName(for: leaf)).font(TypographyToken.body)
            Spacer()
            Text("\(Int(viewModel.kcal(for: leaf))) kcal")
                .font(TypographyToken.caption)
                .foregroundStyle(ColorToken.secondaryText)
        }
        .swipeActions {
            Button("Löschen", role: .destructive) { Task { await viewModel.delete(entryID: leaf.id) } }
        }
        .contextMenu { folderMenu(for: leaf, currentFolder: folderID) }
    }

    @ViewBuilder
    private func folderMenu(for leaf: QuickListLeaf, currentFolder: UUID?) -> some View {
        if currentFolder != nil {
            Button("Aus Ordner lösen") { Task { await viewModel.moveLeaf(leaf.id, toFolder: nil) } }
        }
        ForEach(folderChoices(excluding: currentFolder), id: \.0) { folderID, name in
            Button("Verschieben nach: \(name)") { Task { await viewModel.moveLeaf(leaf.id, toFolder: folderID) } }
        }
    }

    private func folderChoices(excluding: UUID?) -> [(UUID, String)] {
        viewModel.quickList.entries.compactMap { entry in
            guard case let .folder(id, name, _) = entry, id != excluding else { return nil }
            return (id, name)
        }
    }
}
