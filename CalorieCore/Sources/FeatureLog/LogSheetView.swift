import DesignSystem
import Domain
import SwiftUI

/// Log-Sheet: fokussiertes Suchfeld + Barcode-Button, gerankte Ergebnisliste,
/// Tap → Mengeneingabe, Fußzeile „Schnelleintrag". Kennt `FeatureScanner` bewusst
/// nicht – die Scanner-Destination wird vom Composition Root injiziert.
public struct LogSheetView<ScannerDestination: View>: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: LogViewModel
    @State private var searchText = ""
    @State private var selectedFood: Food?
    @State private var isShowingQuickAdd = false
    @State private var isShowingScanner = false
    @FocusState private var isSearchFocused: Bool

    private let scannerDestination: () -> ScannerDestination

    public init(
        foodCatalogRepository: any FoodCatalogRepository,
        foodDataSource: any FoodDataSource,
        diaryRepository: any DiaryRepository,
        @ViewBuilder scannerDestination: @escaping () -> ScannerDestination
    ) {
        _viewModel = State(initialValue: LogViewModel(
            foodCatalogRepository: foodCatalogRepository, foodDataSource: foodDataSource, diaryRepository: diaryRepository
        ))
        self.scannerDestination = scannerDestination
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar
                resultsContent
            }
            .safeAreaInset(edge: .bottom) { quickAddFooter }
            .navigationTitle("Erfassen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fertig") { dismiss() }
                }
            }
            .navigationDestination(item: $selectedFood) { food in
                AmountEntryView(
                    food: food,
                    diaryRepository: viewModel.diaryRepository,
                    foodCatalogRepository: viewModel.foodCatalogRepository
                ) {
                    dismiss()
                }
            }
            .sheet(isPresented: $isShowingQuickAdd) {
                QuickAddView(diaryRepository: viewModel.diaryRepository) {
                    isShowingQuickAdd = false
                    dismiss()
                }
            }
            .fullScreenCover(isPresented: $isShowingScanner) {
                scannerDestination()
            }
            .task(id: searchText) {
                try? await Task.sleep(nanoseconds: 300_000_000)
                guard !Task.isCancelled else { return }
                await viewModel.search(query: searchText)
            }
            .onAppear { isSearchFocused = true }
        }
    }

    private var searchBar: some View {
        HStack(spacing: Spacing.sm) {
            TextField("Suchen…", text: $searchText)
                .focused($isSearchFocused)
                .textFieldStyle(.roundedBorder)
                .submitLabel(.search)

            Button {
                isShowingScanner = true
            } label: {
                Image(systemName: "barcode.viewfinder")
                    .font(.title3)
            }
            .frame(width: 44, height: 44)
        }
        .padding(Spacing.md)
    }

    private var quickAddFooter: some View {
        Button("Schnelleintrag") {
            isShowingQuickAdd = true
        }
        .padding(Spacing.md)
    }

    @ViewBuilder
    private var resultsContent: some View {
        switch viewModel.state {
        case .empty:
            if searchText.isEmpty {
                ContentUnavailableView("Lebensmittel suchen", systemImage: "magnifyingglass")
            } else {
                ContentUnavailableView.search(text: searchText)
            }
        case .loading:
            ProgressView()
                .frame(maxHeight: .infinity)
        case let .error(message):
            ContentUnavailableView {
                Label("Fehler", systemImage: "wifi.slash")
            } description: {
                Text(message)
            } actions: {
                Button("Erneut versuchen") { Task { await viewModel.search(query: searchText) } }
            }
        case let .loaded(foods):
            List(foods) { food in
                Button {
                    selectedFood = food
                } label: {
                    resultRow(food)
                }
                .buttonStyle(.plain)
            }
            .listStyle(.plain)
        }
    }

    private func resultRow(_ food: Food) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(food.name).font(TypographyToken.body)
                if let brand = food.brand {
                    Text(brand).font(TypographyToken.caption).foregroundStyle(ColorToken.secondaryText)
                }
            }
            Spacer()
            Text("\(Int(food.kcalPer100g)) kcal/100g")
                .font(TypographyToken.caption)
                .foregroundStyle(ColorToken.secondaryText)
        }
    }
}
