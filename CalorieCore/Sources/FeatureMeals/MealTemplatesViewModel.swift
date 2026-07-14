import DesignSystem
import Domain
import Foundation

/// Liste aller Gerichte (Gerichte-Verwaltung). Laden + Löschen; Erstellen/Bearbeiten läuft
/// über `MealEditorViewModel`.
@Observable
@MainActor
public final class MealTemplatesViewModel {
    public private(set) var state: ViewState<[MealTemplate]> = .loading

    private let repository: any MealTemplateRepository

    public init(repository: any MealTemplateRepository) {
        self.repository = repository
    }

    public func load() async {
        do {
            let templates = try await repository.all()
            state = templates.isEmpty ? .empty : .loaded(templates)
        } catch {
            state = .error(message: "Gerichte konnten nicht geladen werden.")
        }
    }

    public func delete(id: UUID) async {
        do {
            try await repository.delete(id: id)
            await load()
        } catch {
            state = .error(message: "Löschen fehlgeschlagen.")
        }
    }
}
