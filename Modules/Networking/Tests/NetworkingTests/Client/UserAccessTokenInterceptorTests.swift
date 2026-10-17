import Alamofire
import Foundation
@testable import Networking
import Testing

struct UserAccessTokenInterceptorTests {
    @Test
    func adaptAddsUserTokenAsBearerAuthorization() async throws {
        // Given
        let sut: any RequestAdapter = UserAccessTokenInterceptor { "user-token" }
        let request = try makeRequest(readToken: "read-token")

        // When
        let adapted = try await adapt(request, with: sut)

        // Assert
        #expect(adapted.value(forHTTPHeaderField: "Authorization") == "Bearer user-token")
    }

    @Test
    func adaptLeavesRequestUnchangedWithoutToken() async throws {
        // Given
        let sut: any RequestAdapter = UserAccessTokenInterceptor { nil }
        let request = try makeRequest(readToken: "read-token")

        // When
        let adapted = try await adapt(request, with: sut)

        // Assert
        #expect(adapted == request)
    }
}

private extension UserAccessTokenInterceptorTests {
    func makeRequest(readToken: String) throws -> URLRequest {
        let url = try #require(URL(string: "https://api.themoviedb.org/4/account/4bc889/movie/watchlist"))
        var request = URLRequest(url: url)
        request.headers.add(.authorization(bearerToken: readToken))
        return request
    }

    func adapt(_ request: URLRequest, with adapter: any RequestAdapter) async throws -> URLRequest {
        let session = Session(configuration: URLSessionConfiguration.af.ephemeral)
        return try await withCheckedThrowingContinuation { continuation in
            adapter.adapt(request, for: session) { result in
                continuation.resume(with: result)
            }
        }
    }
}
