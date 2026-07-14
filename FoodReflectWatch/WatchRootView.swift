import SwiftUI
import Sync

/// Start-Navigation der Watch-App. Zeigt die drei Einstiege und schiebt bei Deep Links direkt
/// den passenden Screen auf den Stack.
struct WatchRootView: View {
    let sync: WatchSyncService
    @Binding var route: WatchRoute?

    var body: some View {
        NavigationStack {
            List {
                ForEach(WatchRoute.allCases, id: \.self) { route in
                    NavigationLink(value: route) {
                        Label(route.title, systemImage: route.iconSystemName)
                    }
                }
            }
            .navigationTitle("FoodReflect")
            .navigationDestination(for: WatchRoute.self) { destination(for: $0) }
            .navigationDestination(item: $route) { destination(for: $0) }
        }
    }

    @ViewBuilder
    private func destination(for route: WatchRoute) -> some View {
        switch route {
        case .weight: WatchWeightView(sync: sync)
        case .quicklog: WatchQuickSelectView(sync: sync)
        case .dashboard: WatchDashboardView(sync: sync)
        }
    }
}

extension WatchRoute {
    var title: String {
        switch self {
        case .weight: "Gewicht"
        case .quicklog: "Schnellauswahl"
        case .dashboard: "Kalorien"
        }
    }

    var iconSystemName: String {
        switch self {
        case .weight: "scalemass"
        case .quicklog: "bolt.fill"
        case .dashboard: "flame.fill"
        }
    }
}
