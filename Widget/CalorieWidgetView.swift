import DesignSystem
import Domain
import SwiftUI
import WidgetKit

struct CalorieWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: CalorieEntry

    private var remaining: Double {
        entry.totals?.remainingKcal ?? 0
    }

    private var progress: Double {
        guard let totals = entry.totals, totals.goals.dailyKcal > 0 else { return 0 }
        return totals.kcal / Double(totals.goals.dailyKcal)
    }

    var body: some View {
        Group {
            switch family {
            case .accessoryCircular:
                circularView
            case .accessoryRectangular:
                rectangularView
            default:
                smallView
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var smallView: some View {
        VStack(spacing: Spacing.xs) {
            ZStack {
                ProgressRing(progress: progress, lineWidth: 8)
                    .frame(width: 70, height: 70)
                Text("\(Int(remaining))")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.6)
            }
            Text("kcal übrig")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var circularView: some View {
        Gauge(value: min(max(progress, 0), 1)) {
            Image(systemName: "flame")
        } currentValueLabel: {
            Text("\(Int(remaining))")
        }
        .gaugeStyle(.accessoryCircularCapacity)
    }

    private var rectangularView: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(Int(remaining)) kcal übrig")
                .font(.headline)
            if let totals = entry.totals {
                Text("\(Int(totals.kcal)) / \(totals.goals.dailyKcal) kcal")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
