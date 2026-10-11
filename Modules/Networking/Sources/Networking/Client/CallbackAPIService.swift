import Alamofire
import Foundation

public nonisolated protocol ICallbackAPIService: Sendable {
    @discardableResult
    func request<Response: Decodable & Sendable>(
        _ endpoint: TMDBEndpoint,
        completion: @escaping @Sendable (Result<Response, any Error>) -> Void
    ) -> APIRequestHandle
}

public nonisolated final class CallbackAPIService: Sendable {
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

// MARK: - ICallbackAPIService
nonisolated extension CallbackAPIService: ICallbackAPIService {
    @discardableResult
    public func request<Response: Decodable & Sendable>(
        _ endpoint: TMDBEndpoint,
        completion: @escaping @Sendable (Result<Response, any Error>) -> Void
    ) -> APIRequestHandle {
        let dataRequest = session.request(endpoint)
            .validate()
            .responseDecodable(of: Response.self, decoder: decoder) { [responseLogger] response in
                responseLogger.log(response, for: endpoint)
                
                switch response.result {
                case .success(let value):
                    completion(.success(value))
                case .failure(let error) where error.isExplicitlyCancelledError:
                    completion(.failure(CancellationError()))
                case .failure(let error):
                    completion(.failure(NetworkError(error)))
                }
            }
        return APIRequestHandle { dataRequest.cancel() }
    }
}
