import Foundation

/// Antwort von `GET /api/v2/product/{barcode}`.
struct OFFProductResponse: Decodable {
    let code: String?
    let product: OFFProductDTO?
    let status: Int
}

/// Antwort der Textsuche. Das externe Suchbackend ("search-a-licious",
/// search.openfoodfacts.org) war zum Zeitpunkt der Implementierung nicht
/// erreichbar (502) und dessen Doku ebenfalls nicht – das Feld mit dem
/// Treffer-Array wird daher gegen mehrere plausible Namen dekodiert
/// (`hits`, `products`, `results`, `docs`). Vor dem produktiven Ausrollen
/// der Suche gegen die echte, dann erreichbare API verifizieren.
struct OFFSearchResponse: Decodable {
    let hits: [OFFProductDTO]

    private enum CodingKeys: String, CodingKey {
        case hits, products, results, docs
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let hits = try container.decodeIfPresent([OFFProductDTO].self, forKey: .hits) {
            self.hits = hits
        } else if let products = try container.decodeIfPresent([OFFProductDTO].self, forKey: .products) {
            hits = products
        } else if let results = try container.decodeIfPresent([OFFProductDTO].self, forKey: .results) {
            hits = results
        } else {
            hits = try container.decodeIfPresent([OFFProductDTO].self, forKey: .docs) ?? []
        }
    }
}

struct OFFProductDTO: Decodable {
    let code: String?
    let productName: String?
    let brands: String?
    let nutriments: OFFNutrimentsDTO?
    /// OFF liefert dieses Feld inkonsistent als String oder Zahl – daher als String
    /// dekodiert und im Mapper toleranzfrei geparst (nil bei Unparsbarkeit).
    let servingQuantity: String?
    let quantity: String?

    private enum CodingKeys: String, CodingKey {
        case code
        case productName = "product_name"
        case brands
        case nutriments
        case servingQuantity = "serving_quantity"
        case quantity
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        code = try container.decodeIfPresent(String.self, forKey: .code)
        productName = try container.decodeIfPresent(String.self, forKey: .productName)
        brands = try container.decodeIfPresent(String.self, forKey: .brands)
        nutriments = try container.decodeIfPresent(OFFNutrimentsDTO.self, forKey: .nutriments)
        quantity = try container.decodeIfPresent(String.self, forKey: .quantity)
        servingQuantity = OFFProductDTO.decodeLossyString(container, .servingQuantity)
    }

    /// `serving_quantity` kommt je nach Endpunkt/Produkt als String oder als Zahl zurück.
    private static func decodeLossyString(
        _ container: KeyedDecodingContainer<CodingKeys>, _ key: CodingKeys
    ) -> String? {
        if let string = try? container.decodeIfPresent(String.self, forKey: key) {
            return string
        }
        if let double = try? container.decodeIfPresent(Double.self, forKey: key) {
            return String(double)
        }
        return nil
    }
}

struct OFFNutrimentsDTO: Decodable {
    let energyKcal100g: Double?
    /// Fallback in kJ, falls `energy-kcal_100g` fehlt (ältere/unvollständige Einträge).
    let energy100g: Double?
    let proteins100g: Double?
    let carbohydrates100g: Double?
    let fat100g: Double?

    private enum CodingKeys: String, CodingKey {
        case energyKcal100g = "energy-kcal_100g"
        case energy100g = "energy_100g"
        case proteins100g = "proteins_100g"
        case carbohydrates100g = "carbohydrates_100g"
        case fat100g = "fat_100g"
    }
}
