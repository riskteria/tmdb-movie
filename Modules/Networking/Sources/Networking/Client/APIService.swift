import Alamofire
import Foundation

public nonisolated protocol IAPIService: Sendable {
    func request<Response: Decodable & Sendable>(_ endpoint: TMDBEndpoint) async throws -> Response
}

public nonisolated final class APIService: Sendable {
    private let session: Session
    private let decoder: JSONDecoder
    private let responseLogger = APIResponseLogger()

    public convenience init(readAccessToken: String) {
        self.init(interceptor: ReadAccessTokenInterceptor(token: readAccessToken))
    }

    init(configuration: URLSessionConfiguration = .af.default, interceptor: (any RequestInterceptor)? = nil) {
        session = Session(configuration: configuration, interceptor: interceptor)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder = decoder
    }
}

// MARK: - IAPIService
nonisolated extension APIService: IAPIService {
    public func request<Response: Decodable & Sendable>(_ endpoint: TMDBEndpoint) async throws -> Response {
        let response = await session.request(endpoint)
            .validate()
            .serializingDecodable(Response.self, decoder: decoder)
            .response
        responseLogger.log(response, for: endpoint)

        switch response.result {
        case .success(let value):
            return value
        case .failure(let error) where error.isExplicitlyCancelledError:
            throw CancellationError()
        case .failure(let error):
            throw NetworkError(error)
        }
    }
}
