import Alamofire
import Foundation

// Sends TMDB's API read access token as a Bearer header, so it never appears in URLs, logs or URLCache keys.
nonisolated struct ReadAccessTokenInterceptor {
    let token: String
}

// MARK: - RequestInterceptor
nonisolated extension ReadAccessTokenInterceptor: RequestInterceptor {
    // The signature must match Alamofire's exactly, `@Sendable` included. Otherwise the protocol's
    // default `adapt`, which passes the request through unchanged, is used instead.
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
