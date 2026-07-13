import Domain
import Foundation

enum OFFProductMapper {
    /// 1 kcal = 4.184 kJ – Standard-Umrechnungsfaktor.
    private static let kJPerKcal = 4.184

    /// Fehlende Nährwerte werden als 0 abgebildet (kein optionales Feld in `Food`,
    /// siehe Abschnitt 3). `RankSearchResultsUseCase.completeness` gewichtet solche
    /// Treffer automatisch niedriger; die UI (Phase 5) kann `kcalPer100g == 0` als
    /// Hinweis auf unvollständige Daten nutzen.
    static func toDomain(dto: OFFProductDTO, fallbackBarcode: String) -> Food? {
        guard let name = dto.productName, !name.isEmpty else { return nil }
        let barcode = dto.code ?? fallbackBarcode
        let kcal = dto.nutriments?.energyKcal100g ?? dto.nutriments?.energy100g.map { $0 / kJPerKcal } ?? 0

        return Food(
            name: name,
            brand: dto.brands,
            barcode: barcode,
            kcalPer100g: kcal,
            proteinPer100g: dto.nutriments?.proteins100g ?? 0,
            carbsPer100g: dto.nutriments?.carbohydrates100g ?? 0,
            fatPer100g: dto.nutriments?.fat100g ?? 0,
            servingSizeGrams: dto.servingQuantity.flatMap(Double.init),
            source: .openFoodFacts(code: barcode)
        )
    }
}
