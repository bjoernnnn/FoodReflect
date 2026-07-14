import SwiftUI
import Sync

/// Kleines Watch-Dashboard hinter der Kalorien-Komplikation: Ring mit Zahl in der Mitte
/// (Übrig/Gegessen je nach Sync-Einstellung), drei Makro-Balken, Sprung zur Schnellauswahl.
struct WatchDashboardView: View {
    let sync: WatchSyncService

    private var snapshot: WatchSnapshot {
        sync.snapshot
    }

    private var ringValue: Double {
        guard snapshot.goalKcal > 0 else { return 0 }
        return min(max(snapshot.consumedKcal / Double(snapshot.goalKcal), 0), 1)
    }

    private var centerText: String {
        switch snapshot.calorieDisplayMode {
        case .remaining: WatchKcalFormatter.compact(snapshot.remainingKcal)
        case .consumed: WatchKcalFormatter.compact(snapshot.consumedKcal)
        }
    }

    private var overGoal: Bool {
        snapshot.consumedKcal > Double(snapshot.goalKcal)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Gauge(value: ringValue) {
                    Text(centerText)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                }
                .gaugeStyle(.accessoryCircularCapacity)
                .tint(overGoal ? WatchTheme.fat : WatchTheme.accent)
                .frame(width: 120, height: 120)

                Text(snapshot.calorieDisplayMode == .remaining ? "übrig" : "gegessen")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                VStack(spacing: 6) {
                    macroBar("Protein", grams: snapshot.proteinGrams, color: WatchTheme.protein)
                    macroBar("Kohlenhydrate", grams: snapshot.carbsGrams, color: WatchTheme.carbs)
                    macroBar("Fett", grams: snapshot.fatGrams, color: WatchTheme.fat)
                }

                NavigationLink {
                    WatchQuickSelectView(sync: sync)
                } label: {
                    Label("Schnellauswahl", systemImage: "bolt.fill")
                }
                .tint(WatchTheme.accent)
            }
            .padding(.horizontal)
        }
        .navigationTitle("Kalorien")
    }

    private func macroBar(_ label: String, grams: Double, color: Color) -> some View {
        HStack {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label)
                .font(.caption2)
            Spacer()
            Text("\(Int(grams.rounded())) g")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}
