/// Gemeinsamer Zustand für ViewModels: kein silent failure, kein Alert-Spam.
/// Views rendern `.error` mit einer Retry-Aktion statt eines Alerts.
public enum ViewState<Value: Sendable>: Sendable {
    case loading
    case loaded(Value)
    case empty
    case error(message: String)
}
