import SwiftUI

/// Einstiegspunkt der Watch-App. Phase 9.1 liefert nur das Grundgerüst: eine Navigation, die
/// per Deep Link aus den Komplikationen den passenden (vorerst Platzhalter-)Screen öffnet.
/// Sync (9.3) und echte Screens (9.4–9.6) folgen in späteren Phasen.
@main
struct FoodReflectWatchApp: App {
    @State private var route: WatchRoute?

    var body: some Scene {
        WindowGroup {
            WatchRootView(route: $route)
                .onOpenURL { url in
                    if let parsed = WatchRoute(url: url) {
                        route = parsed
                    }
                }
        }
    }
}
