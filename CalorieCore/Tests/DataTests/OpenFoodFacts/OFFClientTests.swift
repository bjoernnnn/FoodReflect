import Foundation
import Testing
@testable import Data
@testable import Domain

@Suite("OFFClient", .serialized)
struct OFFClientTests {
    private func makeSUT() -> OFFClient {
        OFFClient(session: MockURLProtocol.makeSession())
    }

    private func stub(statusCode: Int = 200, body: String) {
        let data = Data(body.utf8)
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!, statusCode: statusCode, httpVersion: nil, headerFields: nil
            )!
            return (response, data)
        }
    }

    private func stubFailure(_ error: URLError) {
        MockURLProtocol.requestHandler = { _ in throw error }
    }

    @Test("Echte Nutella-Antwort wird korrekt auf Food gemappt (DoD Phase 3)")
    func realNutellaResponseMapsCorrectly() async throws {
        stub(body: OFFFixtures.nutellaProduct)
        let sut = makeSUT()

        let food = try await sut.fetchProduct(barcode: "3017620422003")

        #expect(food?.name == "Nutella")
        #expect(food?.brand == "Nutella, Ferrero, Yum yum")
        #expect(food?.barcode == "3017620422003")
        #expect(food?.kcalPer100g == 539)
        #expect(food?.proteinPer100g == 6.3)
        #expect(food?.carbsPer100g == 57.5)
        #expect(food?.fatPer100g == 30.9)
        #expect(food?.source == .openFoodFacts(code: "3017620422003"))
    }

    @Test("User-Agent-Header wird gemäß OFF-Richtlinie gesetzt")
    func setsUserAgentHeader() async throws {
        var capturedRequest: URLRequest?
        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            return (
                HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!,
                Data(OFFFixtures.nutellaProduct.utf8)
            )
        }
        let sut = OFFClient(session: MockURLProtocol.makeSession(), userAgent: "FoodReflect/1.0 (test@example.com)")

        _ = try await sut.fetchProduct(barcode: "3017620422003")

        #expect(capturedRequest?.value(forHTTPHeaderField: "User-Agent") == "FoodReflect/1.0 (test@example.com)")
    }

    @Test("status: 0 (nicht gefunden) liefert nil statt Fehler")
    func productNotFoundReturnsNil() async throws {
        stub(body: OFFFixtures.productNotFound)
        let sut = makeSUT()

        let food = try await sut.fetchProduct(barcode: "0000000000000")
        #expect(food == nil)
    }

    @Test("Fehlende kcal_100g fallen auf kJ-Umrechnung zurück")
    func fallsBackToKilojouleConversion() async throws {
        stub(body: OFFFixtures.productWithOnlyKilojoules)
        let sut = makeSUT()

        let food = try await sut.fetchProduct(barcode: "1111111111111")
        // 1046 kJ / 4.184 = 250.0 kcal
        #expect(food?.kcalPer100g != nil)
        #expect(abs((food?.kcalPer100g ?? 0) - 250.0) < 0.1)
        #expect(food?.servingSizeGrams == 45)
    }

    @Test("Timeout wird als DomainError.timeout durchgereicht")
    func timeoutMapsToDomainError() async throws {
        stubFailure(URLError(.timedOut))
        let sut = makeSUT()

        await #expect(throws: DomainError.timeout) {
            try await sut.fetchProduct(barcode: "3017620422003")
        }
    }

    @Test("Fehlendes Netz wird als DomainError.offline durchgereicht")
    func offlineMapsToDomainError() async throws {
        stubFailure(URLError(.notConnectedToInternet))
        let sut = makeSUT()

        await #expect(throws: DomainError.offline) {
            try await sut.fetchProduct(barcode: "3017620422003")
        }
    }

    @Test("Kaputtes JSON wird als DomainError.decoding durchgereicht, kein Crash")
    func malformedJSONMapsToDecodingError() async throws {
        stub(body: OFFFixtures.malformedJSON)
        let sut = makeSUT()

        await #expect(throws: DomainError.self) {
            try await sut.fetchProduct(barcode: "3017620422003")
        }
    }

    @Test("Suche mappt alle Treffer aus dem hits-Array")
    func searchMapsHits() async throws {
        stub(body: OFFFixtures.searchHits)
        let sut = makeSUT()

        let results = try await sut.search(query: "nutella")
        #expect(results.count == 2)
        #expect(results.map(\.name) == ["Nutella", "Kinder Bueno"])
    }

    @Test("Suche toleriert alternative Top-Level-Schlüssel (products statt hits)")
    func searchToleratesAlternateTopLevelKey() async throws {
        stub(body: OFFFixtures.searchProductsAlternateKey)
        let sut = makeSUT()

        let results = try await sut.search(query: "nutella")
        #expect(results.count == 1)
        #expect(results.first?.name == "Nutella")
    }
}
