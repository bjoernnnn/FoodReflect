import DesignSystem
import FeatureDashboard
import FeatureLog
import FeatureScanner
import FeatureSettings
import FeatureWeight
import SwiftUI

/// Tab-Navigation: Heute / Verlauf / Gewicht / Einstellungen. Composition Root für alle
/// Tab-Inhalte – bleibt der einzige Ort, der alle Feature-Module kennt.
struct RootTabView: View {
    @Environment(AppContainer.self) private var container

    var body: some View {
        TabView {
            DashboardView(
                diaryRepository: container.diaryRepository,
                goalsRepository: container.goalsRepository,
                widgetRefreshing: container.widgetRefreshing,
                logSheetDestination: {
                    LogSheetView(
                        foodCatalogRepository: container.foodCatalogRepository,
                        foodDataSource: container.foodDataSource,
                        diaryRepository: container.diaryRepository,
                        widgetRefreshing: container.widgetRefreshing,
                        scannerDestination: { onFoodFound, onBarcodeNotFound, onCancel in
                            ScannerView(
                                foodCatalogRepository: container.foodCatalogRepository,
                                onFoodFound: onFoodFound,
                                onBarcodeNotFound: onBarcodeNotFound,
                                onCancel: onCancel
                            )
                        }
                    )
                }
            )
            .tabItem { Label("Heute", systemImage: "flame.fill") }

            HistoryTabPlaceholder()
                .tabItem { Label("Verlauf", systemImage: "chart.bar.fill") }

            WeightView(weightRepository: container.weightRepository, widgetRefreshing: container.widgetRefreshing)
                .tabItem { Label("Gewicht", systemImage: "scalemass.fill") }

            SettingsView(goalsRepository: container.goalsRepository, widgetRefreshing: container.widgetRefreshing)
                .tabItem { Label("Einstellungen", systemImage: "gearshape.fill") }
        }
        .tint(ColorToken.accent)
    }
}

/// Platzhalter, bis Phase 6 (todo2.md) die echte Verlaufsansicht baut.
private struct HistoryTabPlaceholder: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView("Verlauf", systemImage: "chart.bar.fill", description: Text("Folgt in Phase 6."))
                .navigationTitle("Verlauf")
        }
    }
}
