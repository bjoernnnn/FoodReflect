/// Echte OFF-API-Antworten, live abgerufen gegen `world.openfoodfacts.org` am 2026-07-13
/// (Barcode 3017620422003, Nutella 400g) – dient als authentische Fixture für Decoding-Tests.
/// Als Pretty-Print formatiert (inhaltlich identisch zur Rohantwort), um Zeilenlängen einzuhalten.
enum OFFFixtures {
    static let nutellaProduct = """
    {
      "code": "3017620422003",
      "product": {
        "brands": "Nutella, Ferrero, Yum yum",
        "nutriments": {
          "energy-kcal_100g": 539,
          "energy_100g": 2252,
          "proteins_100g": 6.3,
          "carbohydrates_100g": 57.5,
          "fat_100g": 30.9,
          "sugars_100g": 56.3,
          "salt_100g": 0.107
        },
        "nutrition_data": "on",
        "nutrition_data_prepared_per": "100g",
        "product_name": "Nutella",
        "quantity": ""
      },
      "status": 1,
      "status_verbose": "product found"
    }
    """

    static let productNotFound = """
    {
      "code": "0000000000000",
      "status": 0,
      "status_verbose": "product not found"
    }
    """

    /// Nutriments ohne `energy-kcal_100g` (nur kJ vorhanden) – deckt den Umrechnungsfallback ab.
    static let productWithOnlyKilojoules = """
    {
      "code": "1111111111111",
      "product": {
        "product_name": "Testriegel",
        "brands": "TestBrand",
        "nutriments": {
          "energy_100g": 1046,
          "proteins_100g": 10,
          "carbohydrates_100g": 50,
          "fat_100g": 15
        },
        "serving_quantity": "45"
      },
      "status": 1,
      "status_verbose": "product found"
    }
    """

    /// Best-Effort-Schema für search-a-licious (Top-Level-Feld "hits"), da die echte API beim
    /// Implementieren nicht erreichbar war (siehe OFFSearchResponse-Kommentar).
    static let searchHits = """
    {
      "hits": [
        {
          "code": "3017620422003",
          "product_name": "Nutella",
          "brands": "Ferrero",
          "nutriments": {
            "energy-kcal_100g": 539,
            "proteins_100g": 6.3,
            "carbohydrates_100g": 57.5,
            "fat_100g": 30.9
          }
        },
        {
          "code": "7622300779847",
          "product_name": "Kinder Bueno",
          "brands": "Ferrero",
          "nutriments": {
            "energy-kcal_100g": 542,
            "proteins_100g": 7,
            "carbohydrates_100g": 51,
            "fat_100g": 34.6
          }
        }
      ],
      "count": 2,
      "page": 1,
      "page_size": 20
    }
    """

    /// Alternatives Top-Level-Feld ("products" statt "hits") – deckt die tolerante Dekodierung ab.
    static let searchProductsAlternateKey = """
    {
      "products": [
        {
          "code": "3017620422003",
          "product_name": "Nutella",
          "brands": "Ferrero",
          "nutriments": { "energy-kcal_100g": 539 }
        }
      ],
      "count": 1
    }
    """

    static let malformedJSON = "{ this is not valid json"
}
