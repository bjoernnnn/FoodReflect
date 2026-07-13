/// Signalisiert dem Widget, seine Timeline neu zu laden. Implementiert in `Data`
/// (kapselt WidgetKit), aufgerufen von ViewModels nach jedem Log/Delete/Ziel-Update.
public protocol WidgetRefreshing: Sendable {
    func reloadTimelines()
}
