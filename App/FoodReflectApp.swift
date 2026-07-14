import SwiftUI

@main
struct FoodReflectApp: App {
    @State private var container = AppContainer()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(container)
                .task { await container.watchSync.start() }
                .onChange(of: scenePhase) { _, phase in
                    // Beim Zurückkehren in den Vordergrund den aktuellen Stand zur Watch pushen.
                    if phase == .active {
                        Task { await container.watchSync.pushSnapshot() }
                    }
                }
        }
    }
}
