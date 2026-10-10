import Alamofire
import Foundation
@testable import MovieApp
import Testing

struct ReadAccessTokenInterceptorTests {
    private let sut: any RequestAdapter = ReadAccessTokenInterceptor(token: "read-token")

    @Test
    func adaptAddsBearerAuthorizationHeader() async throws {
        // Given
        let request = URLRequest(url: try #require(URL(string: "https://api.themoviedb.org/3/configuration")))
        let session = Session(configuration: URLSessionConfiguration.af.ephemeral)

        // When
        let adapted: URLRequest = try await withCheckedThrowingContinuation { continuation in
            sut.adapt(request, for: session) { result in
                continuation.resume(with: result)
            }
        }

        // Assert
        #expect(adapted.value(forHTTPHeaderField: "Authorization") == "Bearer read-token")
    }
}
