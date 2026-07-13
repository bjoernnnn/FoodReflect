import Foundation

/// Composition Root: erzeugt und verdrahtet alle konkreten Abhängigkeiten
/// (Repositories, Data Sources, UseCases) und reicht sie manuell per Init an
/// ViewModels weiter. Kein DI-Framework, keine Magie.
///
/// Wird ab Phase 2/3 mit ModelContainer, Repositories und OFFClient befüllt.
@Observable
final class AppContainer {
    init() {}
}
