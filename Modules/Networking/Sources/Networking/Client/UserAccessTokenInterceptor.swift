import Alamofire
import Foundation

nonisolated struct UserAccessTokenInterceptor {
    let accessToken: @Sendable () -> String?
}

// MARK: - RequestInterceptor
nonisolated extension UserAccessTokenInterceptor: RequestInterceptor {
    func adapt(
        _ urlRequest: URLRequest,
        for session: Session,
        completion: @escaping @Sendable (Result<URLRequest, any Error>) -> Void
    ) {
        var request = urlRequest
        if let token = accessToken() {
            request.headers.add(.authorization(bearerToken: token))
        }
        completion(.success(request))
    }
}
