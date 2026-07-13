import Data
import Domain
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

    private static let appGroupID = "group.com.bjoernnnn.foodreflect"

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
    }

    /// App-Group-Store ist der Regelfall (fürs Widget in Phase 7 nötig). Fällt ohne
    /// funktionierende App-Group-Provisionierung (z. B. Simulator ohne Apple-Developer-Team)
    /// auf einen In-Memory-Store zurück, statt die App abstürzen zu lassen.
    private static func makeModelContainer() -> ModelContainer {
        if let appGroupContainer = try? ModelContainerFactory.makeAppGroupContainer(appGroupID: appGroupID) {
            return appGroupContainer
        }
        // In-Memory-Schema ohne I/O; kann unter normalen Umständen nicht fehlschlagen.
        // swiftlint:disable:next force_try
        return try! ModelContainerFactory.makeInMemoryContainer()
    }
}
