/// Remote-Lookup für Produktdaten (z. B. Open Food Facts). Implementiert in `Data`.
/// Über dieses Protokoll bleibt eine zweite Quelle (z. B. USDA) später austauschbar/ergänzbar.
public protocol FoodDataSource: Sendable {
    func fetchProduct(barcode: String) async throws(DomainError) -> Food?
    func search(query: String) async throws(DomainError) -> [Food]
}
