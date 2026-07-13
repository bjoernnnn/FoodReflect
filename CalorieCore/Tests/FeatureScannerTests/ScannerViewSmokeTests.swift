import Testing
@testable import FeatureScanner

/// `DataScannerViewController` erfordert echte Kamera-Hardware und lässt sich nicht
/// sinnvoll im Simulator/Unit-Test unit-testen. Die eigentliche Lookup-Logik
/// (Cache → OFF, Persistieren) ist bereits in `CachingFoodCatalogRepositoryTests`
/// (DataTests) abgedeckt – `ScannerView` selbst ist nur dünner Glue-Code darüber.
@Suite("FeatureScanner")
struct ScannerViewSmokeTests {
    @Test("Modul kompiliert und lässt sich importieren")
    func moduleCompiles() {
        #expect(Bool(true))
    }
}
