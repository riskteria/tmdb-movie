import Alamofire
import Foundation

nonisolated protocol IAPIService: Sendable {
    func request<Response: Decodable & Sendable>(_ endpoint: TMDBEndpoint) async throws -> Response
}

nonisolated final class APIService: Sendable {
    static let shared = APIService(
        interceptor: ReadAccessTokenInterceptor(token: AppConfigs.shared.tmdbReadAccessToken)
    )

    private let session: Session
    private let decoder: JSONDecoder

    init(configuration: URLSessionConfiguration = .af.default, interceptor: (any RequestInterceptor)? = nil) {
        session = Session(configuration: configuration, interceptor: interceptor)
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
