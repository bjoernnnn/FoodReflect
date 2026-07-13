/// Herkunft eines Katalog-Eintrags.
public enum FoodSource: Hashable, Sendable {
    case openFoodFacts(code: String)
    case manual
}
