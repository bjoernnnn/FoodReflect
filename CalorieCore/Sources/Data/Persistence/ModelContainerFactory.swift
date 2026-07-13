import Foundation
import SwiftData

public enum ModelContainerFactory {
    public enum Error: Swift.Error {
        case appGroupContainerUnavailable(String)
    }

    static var schema: Schema {
        Schema([SDFood.self, SDDiaryEntry.self, SDGoals.self])
    }

    /// Store liegt im App-Group-Container, damit das Widget (Phase 7) denselben Store lesen kann.
    public static func makeAppGroupContainer(appGroupID: String) throws -> ModelContainer {
        guard let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            throw Error.appGroupContainerUnavailable(appGroupID)
        }
        let storeURL = groupURL.appending(path: "FoodReflect.sqlite")
        let configuration = ModelConfiguration(schema: schema, url: storeURL)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    public static func makeInMemoryContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
