import Data
import Domain
import Foundation
import SwiftData

/// Composition Root: erzeugt und verdrahtet alle konkreten Abhängigkeiten
/// (Repositories, Data Sources) und reicht sie manuell per Init an ViewModels
/// weiter. Kein DI-Framework, keine Magie.
@Observable
@MainActor
final class AppContainer {
    let diaryRepository: any DiaryRepository
    let goalsRepository: any GoalsRepository
    let foodCatalogRepository: any FoodCatalogRepository
    let foodDataSource: any FoodDataSource
    let weightRepository: any WeightRepository
    let widgetRefreshing: any WidgetRefreshing

    init() {
        let modelContainer = Self.makeModelContainer()
        let offClient = OFFClient()

        diaryRepository = SwiftDataDiaryRepository(modelContainer: modelContainer)
        goalsRepository = SwiftDataGoalsRepository(modelContainer: modelContainer)
        foodCatalogRepository = CachingFoodCatalogRepository(
            localCache: SwiftDataFoodCatalogRepository(modelContainer: modelContainer),
            remoteDataSource: offClient
        )
        foodDataSource = offClient
        weightRepository = SwiftDataWeightRepository(modelContainer: modelContainer)
        widgetRefreshing = WidgetCenterRefresher()
    }

    /// App-Group-Store ist der Regelfall (fürs Widget nötig, liest denselben Store read-only).
    /// Fällt ohne funktionierende App-Group-Provisionierung (z. B. Simulator ohne
    /// Apple-Developer-Team) auf einen In-Memory-Store zurück, statt die App abstürzen zu lassen.
    /// Der UI-Test startet zusätzlich immer mit einem frischen In-Memory-Store
    /// (`-UITestReset`), damit jeder Testlauf deterministisch bei Onboarding beginnt.
    private static func makeModelContainer() -> ModelContainer {
        let isUITesting = ProcessInfo.processInfo.arguments.contains("-UITestReset")
        if !isUITesting, let appGroupContainer = try? ModelContainerFactory.makeAppGroupContainer(appGroupID: AppGroup.id) {
            return appGroupContainer
        }
        // In-Memory-Schema ohne I/O; kann unter normalen Umständen nicht fehlschlagen.
        // swiftlint:disable:next force_try
        return try! ModelContainerFactory.makeInMemoryContainer()
    }
}
