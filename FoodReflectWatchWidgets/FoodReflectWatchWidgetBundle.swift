import Foundation
import SwiftUI
import Sync
import WidgetKit

/// Die drei Zifferblatt-Komplikationen. Sie lesen den zuletzt vom iPhone gesyncten Snapshot
/// aus dem watch-internen App-Group-Cache (`AppGroupSnapshotStore`); die Watch-App lädt die
/// Timelines nach jedem Sync-Event neu (`WidgetCenter.reloadAllTimelines`).
@main
struct FoodReflectWatchWidgetBundle: WidgetBundle {
    var body: some Widget {
        WeightComplication()
        QuickSelectComplication()
        CalorieRingComplication()
    }
}

private enum WidgetTheme {
    static let accent = Color(red: 0.086, green: 0.635, blue: 0.573)
    static let over = Color(red: 0.93, green: 0.31, blue: 0.55)
    static let appGroupID = "group.com.bjoernnnn.foodreflect.watch"
}

// MARK: - Provider (liest den gecachten Snapshot)

struct SnapshotEntry: TimelineEntry {
    let date: Date
    let snapshot: WatchSnapshot
}

struct SnapshotProvider: TimelineProvider {
    func placeholder(in _: Context) -> SnapshotEntry {
        SnapshotEntry(date: .now, snapshot: .sample)
    }

    func getSnapshot(in context: Context, completion: @escaping (SnapshotEntry) -> Void) {
        // In der Zifferblatt-Galerie repräsentative Beispieldaten zeigen, sonst den echten Cache.
        completion(context.isPreview ? SnapshotEntry(date: .now, snapshot: .sample) : load())
    }

    func getTimeline(in _: Context, completion: @escaping (Timeline<SnapshotEntry>) -> Void) {
        // Nächster planmäßiger Reload zum Tageswechsel (Kalorien-Reset); Sync-Events triggern
        // zusätzlich sofortige Reloads über WidgetCenter.
        let nextMidnight = Calendar.current.nextDate(
            after: .now,
            matching: DateComponents(hour: 0, minute: 0),
            matchingPolicy: .nextTime
        ) ?? .now.addingTimeInterval(3600)
        completion(Timeline(entries: [load()], policy: .after(nextMidnight)))
    }

    private func load() -> SnapshotEntry {
        let store = AppGroupSnapshotStore(suiteName: WidgetTheme.appGroupID)
        return SnapshotEntry(date: .now, snapshot: store.load() ?? .empty)
    }
}

// MARK: - Gewicht („81,4" bzw. Waagen-Symbol als Fallback)

struct WeightComplication: Widget {
    let kind = "FoodReflectWeightComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SnapshotProvider()) { entry in
            WeightComplicationView(snapshot: entry.snapshot)
                .widgetURL(URL(string: "foodreflect://watch/weight"))
        }
        .configurationDisplayName("Gewicht")
        .description("Aktuelles Gewicht schnell eintragen.")
        .supportedFamilies([.accessoryCircular, .accessoryInline, .accessoryCorner])
    }
}

struct WeightComplicationView: View {
    let snapshot: WatchSnapshot

    var body: some View {
        if let weight = snapshot.latestWeightKg {
            Text(String(format: "%.1f", weight).replacingOccurrences(of: ".", with: ","))
                .font(.system(.title3, design: .rounded).bold())
                .minimumScaleFactor(0.5)
        } else {
            Image(systemName: "scalemass")
        }
    }
}

// MARK: - Schnellauswahl (Icon)

struct QuickSelectComplication: Widget {
    let kind = "FoodReflectQuickSelectComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SnapshotProvider()) { _ in
            Image(systemName: "bolt.fill")
                .foregroundStyle(WidgetTheme.accent)
                .widgetURL(URL(string: "foodreflect://watch/quicklog"))
        }
        .configurationDisplayName("Schnellauswahl")
        .description("Gerichte und Lebensmittel per Tipp loggen.")
        .supportedFamilies([.accessoryCircular, .accessoryCorner])
    }
}

// MARK: - Kalorien-Ring (Gauge + Zahl in deutscher Kurzform)

struct CalorieRingComplication: Widget {
    let kind = "FoodReflectCalorieRingComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SnapshotProvider()) { entry in
            CalorieRingView(snapshot: entry.snapshot)
                .widgetURL(URL(string: "foodreflect://watch/dashboard"))
        }
        .configurationDisplayName("Kalorien-Ring")
        .description("Tagesfortschritt als Ring.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular])
    }
}

struct CalorieRingView: View {
    let snapshot: WatchSnapshot

    private var value: Double {
        guard snapshot.goalKcal > 0 else { return 0 }
        return min(max(snapshot.consumedKcal / Double(snapshot.goalKcal), 0), 1)
    }

    private var centerText: String {
        switch snapshot.calorieDisplayMode {
        case .remaining: WatchKcalFormatter.compact(snapshot.remainingKcal)
        case .consumed: WatchKcalFormatter.compact(snapshot.consumedKcal)
        }
    }

    var body: some View {
        Gauge(value: value) {
            Text(centerText)
                .minimumScaleFactor(0.5)
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .tint(snapshot.consumedKcal > Double(snapshot.goalKcal) ? WidgetTheme.over : WidgetTheme.accent)
    }
}
