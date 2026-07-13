import Domain
import Foundation

/// Remote-Lookup gegen Open Food Facts (v2 REST für Barcode, "search-a-licious"
/// für Textsuche). Netz nur für Produkt-Lookup – Tagebuch/Ziele/Historie sind
/// vollständig lokal.
public struct OFFClient: FoodDataSource, Sendable {
    private let session: URLSession
    private let userAgent: String
    private let productBaseURL: URL
    private let searchBaseURL: URL

    public init(
        session: URLSession = .shared,
        userAgent: String = "FoodReflect/1.0 (kontakt@bjoernnnn.foodreflect.example)",
        productBaseURL: URL = URL(string: "https://world.openfoodfacts.org")!,
        searchBaseURL: URL = URL(string: "https://search.openfoodfacts.org")!
    ) {
        self.session = session
        self.userAgent = userAgent
        self.productBaseURL = productBaseURL
        self.searchBaseURL = searchBaseURL
    }

    private static let requestedFields = "code,product_name,brands,nutriments,serving_quantity,quantity"

    public func fetchProduct(barcode: String) async throws(DomainError) -> Food? {
        var components = URLComponents(
            url: productBaseURL.appending(path: "api/v2/product/\(barcode)"),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [URLQueryItem(name: "fields", value: Self.requestedFields)]
        guard let url = components?.url else { throw DomainError.decoding("invalid URL") }

        let data = try await get(url)
        let response: OFFProductResponse
        do {
            response = try JSONDecoder().decode(OFFProductResponse.self, from: data)
        } catch {
            throw DomainError.decoding("\(error)")
        }

        guard response.status == 1, let dto = response.product else { return nil }
        return OFFProductMapper.toDomain(dto: dto, fallbackBarcode: response.code ?? barcode)
    }

    public func search(query: String) async throws(DomainError) -> [Food] {
        var components = URLComponents(url: searchBaseURL.appending(path: "search"), resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "page_size", value: "20"),
            URLQueryItem(name: "fields", value: Self.requestedFields)
        ]
        guard let url = components?.url else { throw DomainError.decoding("invalid URL") }

        let data = try await get(url)
        let response: OFFSearchResponse
        do {
            response = try JSONDecoder().decode(OFFSearchResponse.self, from: data)
        } catch {
            throw DomainError.decoding("\(error)")
        }

        return response.hits.compactMap { OFFProductMapper.toDomain(dto: $0, fallbackBarcode: $0.code ?? "") }
    }

    private func get(_ url: URL) async throws(DomainError) -> Data {
        var request = URLRequest(url: url, timeoutInterval: 10)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")

        do {
            let (data, _) = try await session.data(for: request)
            return data
        } catch let error as URLError {
            switch error.code {
            case .timedOut:
                throw DomainError.timeout
            case .notConnectedToInternet, .networkConnectionLost:
                throw DomainError.offline
            default:
                throw DomainError.network(error.localizedDescription)
            }
        } catch {
            throw DomainError.network("\(error)")
        }
    }
}
