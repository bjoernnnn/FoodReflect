import SwiftUI

/// Start-Navigation der Watch-App. Zeigt die drei Einstiege (Gewicht, Schnellauswahl, Kalorien)
/// und schiebt bei Deep Links direkt den passenden Screen auf den Stack.
struct WatchRootView: View {
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
            .navigationDestination(for: WatchRoute.self) { route in
                WatchPlaceholderScreen(route: route)
            }
            .navigationDestination(item: $route) { route in
                WatchPlaceholderScreen(route: route)
            }
        }
    }
}

/// Platzhalter, bis die echten Screens in Phase 9.4–9.6 kommen. Dunkel & minimal (Abschnitt 7).
struct WatchPlaceholderScreen: View {
    let route: WatchRoute

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: route.iconSystemName)
                .font(.system(size: 32, weight: .semibold))
            Text(route.title)
                .font(.headline)
            Text("Kommt in einer späteren Phase.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .navigationTitle(route.title)
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
