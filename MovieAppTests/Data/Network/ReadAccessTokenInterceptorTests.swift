import Alamofire
import Foundation
@testable import MovieApp
import Testing

struct ReadAccessTokenInterceptorTests {
    private let sut = ReadAccessTokenInterceptor(token: "read-token")

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

    @Test
    func sessionSendsTokenAsHeaderAndNotInQuery() async throws {
        // Given
        let configuration = URLSessionConfiguration.af.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        let client = APIClient(session: Session(configuration: configuration, interceptor: sut))
        let endpoint = TMDBEndpoint.movieGenres(parameters: .init(language: "en-US"))
        try URLProtocolStub.stub(endpoint, with: .json(statusCode: 200, body: #"{"genres": []}"#))

        // When
        let _: MovieGenresDTO.Response = try await client.send(endpoint)

        // Assert
        let request = try #require(try URLProtocolStub.lastRequest(for: endpoint))
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer read-token")
        #expect(request.url?.query?.contains("read-token") == false)
    }
}
