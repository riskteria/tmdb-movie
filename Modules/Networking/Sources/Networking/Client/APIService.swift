import Alamofire
import Foundation

public nonisolated protocol IAPIService: Sendable {
    func request<Response: Decodable & Sendable>(_ endpoint: TMDBEndpoint) async throws -> Response
}

public nonisolated final class APIService: Sendable {
    private let session: Session
    private let decoder: JSONDecoder
    private let responseLogger = APIResponseLogger()
    private let userAccessTokenInterceptor: UserAccessTokenInterceptor?

    public convenience init(readAccessToken: String, userAccessToken: @escaping @Sendable () -> String? = { nil }) {
        self.init(
            interceptor: ReadAccessTokenInterceptor(token: readAccessToken),
            userAccessTokenInterceptor: UserAccessTokenInterceptor(accessToken: userAccessToken)
        )
    }

    init(
        configuration: URLSessionConfiguration = .af.default,
        interceptor: (any RequestInterceptor)? = nil,
        userAccessTokenInterceptor: UserAccessTokenInterceptor? = nil
    ) {
        session = Session(configuration: configuration, interceptor: interceptor)
        self.userAccessTokenInterceptor = userAccessTokenInterceptor
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder = decoder
    }
}

// MARK: - IAPIService
nonisolated extension APIService: IAPIService {
    public func request<Response: Decodable & Sendable>(_ endpoint: TMDBEndpoint) async throws -> Response {
        let response = await session.request(endpoint, interceptor: requestInterceptor(for: endpoint))
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

nonisolated extension APIService {
    func requestInterceptor(for endpoint: TMDBEndpoint) -> UserAccessTokenInterceptor? {
        switch endpoint.authorization {
        case .readAccessToken:
            nil
        case .userAccessToken:
            userAccessTokenInterceptor
        }
    }
}
