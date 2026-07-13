import Domain
import WidgetKit

public struct WidgetCenterRefresher: WidgetRefreshing {
    public init() {}

    public func reloadTimelines() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
