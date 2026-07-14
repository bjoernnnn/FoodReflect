import SwiftUI
import WidgetKit

/// Die drei Zifferblatt-Komplikationen der Watch-App. Phase 9.1: statische Platzhalter-Inhalte
/// mit korrekten Deep Links und unterstützten Familien. Echte Daten (Sync-Snapshot) + Gauge/Ring
/// folgen in Phase 9.3/9.6.
@main
struct FoodReflectWatchWidgetBundle: WidgetBundle {
    var body: some Widget {
        WeightComplication()
        QuickSelectComplication()
        CalorieRingComplication()
    }
}

// MARK: - Gemeinsamer Platzhalter-Entry

struct WatchPlaceholderEntry: TimelineEntry {
    let date: Date
}

struct WatchPlaceholderProvider: TimelineProvider {
    func placeholder(in _: Context) -> WatchPlaceholderEntry {
        WatchPlaceholderEntry(date: .now)
    }

    func getSnapshot(in _: Context, completion: @escaping (WatchPlaceholderEntry) -> Void) {
        completion(WatchPlaceholderEntry(date: .now))
    }

    func getTimeline(in _: Context, completion: @escaping (Timeline<WatchPlaceholderEntry>) -> Void) {
        completion(Timeline(entries: [WatchPlaceholderEntry(date: .now)], policy: .never))
    }
}

// MARK: - Gewicht (bevorzugt „XX,X", hier Platzhalter-Symbol bis Sync existiert)

struct WeightComplication: Widget {
    let kind = "FoodReflectWeightComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WatchPlaceholderProvider()) { _ in
            Image(systemName: "scalemass")
                .widgetURL(URL(string: "foodreflect://watch/weight"))
        }
        .configurationDisplayName("Gewicht")
        .description("Aktuelles Gewicht schnell eintragen.")
        .supportedFamilies([.accessoryCircular, .accessoryInline, .accessoryCorner])
    }
}

// MARK: - Schnellauswahl (Icon-Komplikation, Deep Link zum Logging)

struct QuickSelectComplication: Widget {
    let kind = "FoodReflectQuickSelectComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WatchPlaceholderProvider()) { _ in
            Image(systemName: "bolt.fill")
                .widgetURL(URL(string: "foodreflect://watch/quicklog"))
        }
        .configurationDisplayName("Schnellauswahl")
        .description("Gerichte und Lebensmittel per Tipp loggen.")
        .supportedFamilies([.accessoryCircular, .accessoryCorner])
    }
}

// MARK: - Kalorien-Ring (Platzhalter-Gauge bis Sync-Snapshot existiert)

struct CalorieRingComplication: Widget {
    let kind = "FoodReflectCalorieRingComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WatchPlaceholderProvider()) { _ in
            Gauge(value: 0) {
                Image(systemName: "flame.fill")
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .widgetURL(URL(string: "foodreflect://watch/dashboard"))
        }
        .configurationDisplayName("Kalorien-Ring")
        .description("Tagesfortschritt als Ring.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular])
    }
}
