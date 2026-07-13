/// Herkunft eines Katalog-Eintrags.
public enum FoodSource: Equatable, Sendable {
    case openFoodFacts(code: String)
    case manual
}
