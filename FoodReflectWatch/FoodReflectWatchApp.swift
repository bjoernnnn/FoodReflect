import SwiftUI
import Sync
import WidgetKit

/// Einstiegspunkt der Watch-App. Besitzt den `WatchSyncService` (autoritativer Snapshot vom
/// iPhone + Event-Versand) und öffnet per Deep Link aus den Komplikationen den passenden Screen.
@main
struct FoodReflectWatchApp: App {
    @State private var sync = WatchSyncService(
        snapshotStore: AppGroupSnapshotStore(suiteName: WatchTheme.appGroupID),
        onSnapshotChanged: { WidgetCenter.shared.reloadAllTimelines() }
    )
    @State private var route: WatchRoute?

    var body: some Scene {
        WindowGroup {
            WatchRootView(sync: sync, route: $route)
                .tint(WatchTheme.accent)
                .onAppear { sync.activate() }
                .onOpenURL { url in
                    if let parsed = WatchRoute(url: url) {
                        route = parsed
                    }
                }
        }
    }
}
