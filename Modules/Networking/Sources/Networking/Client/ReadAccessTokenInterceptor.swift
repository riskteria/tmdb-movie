import Alamofire
import Foundation

nonisolated struct ReadAccessTokenInterceptor {
    let token: String
}

// MARK: - RequestInterceptor
nonisolated extension ReadAccessTokenInterceptor: RequestInterceptor {
    func adapt(
        _ urlRequest: URLRequest,
        for session: Session,
        completion: @escaping @Sendable (Result<URLRequest, any Error>) -> Void
    ) {
        var request = urlRequest
        request.headers.add(.authorization(bearerToken: token))
        completion(.success(request))
    }
}
