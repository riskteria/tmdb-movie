import Foundation
@testable import Networking
import Testing

// Each test requests its own page of Popular so the URL stubs never collide.
struct APIServiceTests {
    private static let pageJSON = """
        {
            "page": 1,
            "results": [{\(TMDBJSON.movieSummaryFields)}],
            "total_pages": 1,
            "total_results": 1
        }
        """

    private let sut: any IAPIService = APIService.makeStub()

    @Test
    func requestDecodesSuccessfulResponse() async throws {
        // Given
        let endpoint = Self.popularMovies(page: 1)
        try URLProtocolStub.stub(endpoint, with: .json(statusCode: 200, body: Self.pageJSON))

        // When
        let response: MovieListDTO.Response = try await sut.request(endpoint)

        // Assert
        #expect(response.results.map(\.id) == [693134])
    }

    @Test
    func requestMapsUnsuccessfulStatusToInvalidResponse() async throws {
        // Given
        let endpoint = Self.popularMovies(page: 2)
        let body = #"{"status_code": 7, "status_message": "Invalid API key"}"#
        try URLProtocolStub.stub(endpoint, with: .json(statusCode: 401, body: body))

        // When & Assert
        await #expect(throws: NetworkError.invalidResponse(statusCode: 401)) {
            let _: MovieListDTO.Response = try await sut.request(endpoint)
        }
    }

    @Test
    func requestMapsMalformedBodyToDecodingFailed() async throws {
        // Given
        let endpoint = Self.popularMovies(page: 3)
        try URLProtocolStub.stub(endpoint, with: .json(statusCode: 200, body: #"{"page": 1}"#))

        // When & Assert
        await #expect(throws: NetworkError.decodingFailed) {
            let _: MovieListDTO.Response = try await sut.request(endpoint)
        }
    }

    @Test
    func requestMapsTransportErrorToRequestFailed() async throws {
        // Given
        let endpoint = Self.popularMovies(page: 4)

        // When & Assert
        await #expect(throws: NetworkError.requestFailed) {
            let _: MovieListDTO.Response = try await sut.request(endpoint)
        }
    }

    @Test(.timeLimit(.minutes(1)))
    func requestThrowsCancellationErrorWhenTaskIsCancelled() async throws {
        // Given
        let endpoint = Self.popularMovies(page: 5)
        try URLProtocolStub.stub(endpoint, with: .noResponse)
        let client = sut

        // When
        let task = Task {
            let _: MovieListDTO.Response = try await client.request(endpoint)
        }
        task.cancel()

        // Assert
        await #expect(throws: CancellationError.self) {
            try await task.value
        }
    }

    @Test
    func userTokenEndpointGetsUserTokenInterceptor() {
        // Given
        let service = APIService(readAccessToken: "read-token") { "user-token" }
        let endpoint = TMDBEndpoint.accountMovies(accountObjectID: "4bc889", category: .watchlist, parameters: .init())

        // When
        let interceptor = service.requestInterceptor(for: endpoint)

        // Assert
        #expect(interceptor?.accessToken() == "user-token")
    }

    @Test
    func contentEndpointGetsNoExtraInterceptor() {
        // Given
        let service = APIService(readAccessToken: "read-token") { "user-token" }

        // When
        let interceptor = service.requestInterceptor(for: Self.popularMovies(page: 1))

        // Assert
        #expect(interceptor == nil)
    }

    @Test
    func authEndpointGetsNoExtraInterceptor() {
        // Given
        let service = APIService(readAccessToken: "read-token") { "user-token" }
        let endpoint = TMDBEndpoint.createRequestToken(request: .init(redirectTo: "movieapp://auth"))

        // When
        let interceptor = service.requestInterceptor(for: endpoint)

        // Assert
        #expect(interceptor == nil)
    }

    private static func popularMovies(page: Int) -> TMDBEndpoint {
        .movieList(category: .popular, parameters: .init(page: page))
    }
}
