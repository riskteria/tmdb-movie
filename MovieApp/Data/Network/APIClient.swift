import Alamofire
import Foundation

nonisolated final class APIClient: Sendable {
    private let session: Session
    private let decoder: JSONDecoder

    init(session: Session) {
        self.session = session
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder = decoder
    }

    func send<Response: Decodable & Sendable>(_ endpoint: TMDBEndpoint) async throws -> Response {
        let result = await session.request(endpoint)
            .validate()
            .serializingDecodable(Response.self, decoder: decoder)
            .result
        switch result {
        case .success(let response):
            return response
        case .failure(let error) where error.isExplicitlyCancelledError:
            throw CancellationError()
        case .failure(let error):
            throw NetworkError(error)
        }
    }
}
