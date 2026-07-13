import SwiftUI
import WidgetKit

struct CalorieWidget: Widget {
    let kind = "CalorieWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CalorieTimelineProvider()) { entry in
            CalorieWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("FoodReflect")
        .description("Zeigt deine verbleibenden Kalorien für heute.")
        .supportedFamilies([.systemSmall, .accessoryCircular, .accessoryRectangular])
    }
}

@main
struct CalorieWidgetBundle: WidgetBundle {
    var body: some Widget {
        CalorieWidget()
    }
}
