import FeatureDashboard
import FeatureLog
import FeatureScanner
import FeatureSettings
import SwiftUI

/// Weiche zwischen Onboarding und Dashboard, anhand ob bereits Ziele gespeichert sind.
struct RootView: View {
    @Environment(AppContainer.self) private var container
    @State private var hasCompletedOnboarding: Bool?

    var body: some View {
        Group {
            switch hasCompletedOnboarding {
            case nil:
                ProgressView()
            case false:
                OnboardingView(goalsRepository: container.goalsRepository) {
                    hasCompletedOnboarding = true
                }
            case true:
                DashboardView(
                    diaryRepository: container.diaryRepository,
                    goalsRepository: container.goalsRepository,
                    widgetRefreshing: container.widgetRefreshing,
                    settingsDestination: {
                        SettingsView(goalsRepository: container.goalsRepository, widgetRefreshing: container.widgetRefreshing)
                    },
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
            }
        }
        .task {
            guard hasCompletedOnboarding == nil else { return }
            let goals = try? await container.goalsRepository.currentGoals()
            hasCompletedOnboarding = goals != nil
        }
    }
}
