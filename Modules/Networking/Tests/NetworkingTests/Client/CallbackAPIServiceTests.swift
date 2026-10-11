import Foundation
@testable import Networking
import Testing

struct CallbackAPIServiceTests {
    private static let pageJSON = """
        {
            "page": 1,
            "results": [{\(TMDBJSON.movieSummaryFields)}],
            "total_pages": 1,
            "total_results": 1
        }
        """

    private let sut: any ICallbackAPIService = CallbackAPIService.makeStub()

    @Test
    func requestDeliversDecodedResponse() async throws {
        // Given
        let endpoint = Self.popularMovies(page: 101)
        try URLProtocolStub.stub(endpoint, with: .json(statusCode: 200, body: Self.pageJSON))

        // When
        let result: Result<MovieListDTO.Response, any Error> = await response(for: endpoint)

        // Assert
        #expect(try result.get().results.map(\.id) == [693134])
    }

    @Test
    func requestMapsUnsuccessfulStatusToInvalidResponse() async throws {
        // Given
        let endpoint = Self.popularMovies(page: 102)
        let body = #"{"status_code": 7, "status_message": "Invalid API key"}"#
        try URLProtocolStub.stub(endpoint, with: .json(statusCode: 401, body: body))

        // When
        let result: Result<MovieListDTO.Response, any Error> = await response(for: endpoint)

        // Assert
        #expect(throws: NetworkError.invalidResponse(statusCode: 401)) {
            try result.get()
        }
    }

    @Test
    func requestMapsMalformedBodyToDecodingFailed() async throws {
        // Given
        let endpoint = Self.popularMovies(page: 103)
        try URLProtocolStub.stub(endpoint, with: .json(statusCode: 200, body: #"{"page": 1}"#))

        // When
        let result: Result<MovieListDTO.Response, any Error> = await response(for: endpoint)

        // Assert
        #expect(throws: NetworkError.decodingFailed) {
            try result.get()
        }
    }

    @Test
    func requestMapsTransportErrorToRequestFailed() async {
        // Given
        let endpoint = Self.popularMovies(page: 104)

        // When
        let result: Result<MovieListDTO.Response, any Error> = await response(for: endpoint)

        // Assert
        #expect(throws: NetworkError.requestFailed) {
            try result.get()
        }
    }

    @Test(.timeLimit(.minutes(1)))
    func requestDeliversCancellationErrorWhenCancelled() async throws {
        // Given
        let endpoint = Self.popularMovies(page: 105)
        try URLProtocolStub.stub(endpoint, with: .noResponse)

        // When
        let result: Result<MovieListDTO.Response, any Error> = await withCheckedContinuation { continuation in
            let handle = sut.request(endpoint) { (result: Result<MovieListDTO.Response, any Error>) in
                continuation.resume(returning: result)
            }
            handle.cancel()
        }

        // Assert
        #expect(throws: CancellationError.self) {
            try result.get()
        }
    }

    private func response<Response: Decodable & Sendable>(for endpoint: TMDBEndpoint) async -> Result<Response, any Error> {
        await withCheckedContinuation { continuation in
            sut.request(endpoint) { (result: Result<Response, any Error>) in
                continuation.resume(returning: result)
            }
        }
    }

    private static func popularMovies(page: Int) -> TMDBEndpoint {
        .movieList(category: .popular, parameters: .init(page: page))
    }
}
