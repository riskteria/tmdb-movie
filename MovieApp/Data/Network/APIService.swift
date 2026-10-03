import Alamofire
import Foundation

nonisolated protocol IAPIService: Sendable {
    func request<Response: Decodable & Sendable>(_ endpoint: TMDBEndpoint) async throws -> Response
}

nonisolated final class APIService: Sendable {
    private let session: Session
    private let decoder: JSONDecoder

    init(session: Session) {
        self.session = session
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder = decoder
    }
}

nonisolated extension APIService: IAPIService {
    func request<Response: Decodable & Sendable>(_ endpoint: TMDBEndpoint) async throws -> Response {
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
