import XCTest

/// UI-Smoke-Test: Onboarding → Schnelleintrag → Dashboard-Zahlen stimmen.
/// Startet mit `-UITestReset` (siehe AppContainer) für einen deterministischen,
/// leeren In-Memory-Store bei jedem Testlauf.
final class KalorienTrackerUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testOnboardingQuickAddDashboardFlow() {
        let app = XCUIApplication()
        app.launchArguments = ["-UITestReset"]
        app.launch()

        // Onboarding: Default 2000 kcal bestätigen.
        let kcalField = app.textFields["onboarding.kcalField"]
        XCTAssertTrue(kcalField.waitForExistence(timeout: 10), "Onboarding-Eingabefeld nicht gefunden")

        let confirmButton = app.buttons["onboarding.confirmButton"]
        XCTAssertTrue(confirmButton.exists)
        confirmButton.tap()

        // Dashboard zeigt das aus dem Onboarding übernommene Ziel als Rest-kcal.
        let remainingKcal = app.descendants(matching: .any)["dashboard.remainingKcal"]
        XCTAssertTrue(remainingKcal.waitForExistence(timeout: 10), "Dashboard nach Onboarding nicht erreicht")
        XCTAssertEqual(Self.digitsOnly(remainingKcal.label), "2000")

        // Erfassen -> Schnelleintrag: 500 kcal loggen.
        app.buttons["dashboard.logButton"].tap()

        let quickAddButton = app.buttons["logSheet.quickAddButton"]
        XCTAssertTrue(quickAddButton.waitForExistence(timeout: 5), "Log-Sheet nicht geöffnet")
        quickAddButton.tap()

        let nameField = app.textFields["quickAdd.nameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5), "Schnelleintrag-Formular nicht geöffnet")
        nameField.tap()
        nameField.typeText("Testsnack")

        let kcalInput = app.textFields["quickAdd.kcalField"]
        kcalInput.tap()
        kcalInput.typeText("500")

        app.buttons["quickAdd.saveButton"].tap()

        // Zurück im Dashboard: Rest-kcal muss um 500 gesunken sein (2000 -> 1500),
        // konsumiert muss 500 zeigen. Reload nach Sheet-Dismiss ist async, daher gepollt.
        let updatedRemaining = app.descendants(matching: .any)["dashboard.remainingKcal"]
        XCTAssertTrue(updatedRemaining.waitForExistence(timeout: 10))

        let remainingUpdated = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in Self.digitsOnly(updatedRemaining.label) == "1500" },
            object: nil
        )
        wait(for: [remainingUpdated], timeout: 10)

        let consumedSummary = app.descendants(matching: .any)["dashboard.consumedSummary"]
        XCTAssertTrue(consumedSummary.exists)
        XCTAssertTrue(
            consumedSummary.label.contains("500"),
            "Erwartete '500' in der konsumiert-Zusammenfassung, war: \(consumedSummary.label)"
        )
    }

    private static func digitsOnly(_ string: String) -> String {
        String(string.filter(\.isNumber))
    }
}
