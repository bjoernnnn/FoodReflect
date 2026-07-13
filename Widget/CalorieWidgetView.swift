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

    /// Dieselbe Makro-Farbaufteilung wie im Dashboard-Ring der App, für einen konsistenten
    /// Auftritt zwischen Home-Screen-Widget und App.
    private var macroSegments: [RingSegment] {
        guard let totals = entry.totals else { return [] }
        return [
            RingSegment(value: max(totals.protein * 4, 0), color: ColorToken.proteinColor),
            RingSegment(value: max(totals.carbs * 4, 0), color: ColorToken.carbsColor),
            RingSegment(value: max(totals.fat * 9, 0), color: ColorToken.fatColor)
        ]
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
                SegmentedProgressRing(segments: macroSegments, total: Double(entry.totals?.goals.dailyKcal ?? 0), lineWidth: 8)
                    .frame(width: 70, height: 70)
                    .accessibilityHidden(true)
                Text("\(Int(remaining))")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.6)
            }
            Text("kcal übrig")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
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
