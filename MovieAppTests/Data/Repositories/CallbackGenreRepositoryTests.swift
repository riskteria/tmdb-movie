@testable import MovieApp
@testable import Networking
import Testing

struct CallbackGenreRepositoryTests {
    private let endpoint = TMDBEndpoint.movieGenres(parameters: .init(language: "en-US"))

    @Test
    func movieGenresMapsEveryGenre() async throws {
        // Given
        let apiService = CallbackAPIServiceStub(
            endpoint: endpoint,
            result: .success(try JSONFixture.named(.movieGenres))
        )
        let sut: any ICallbackGenreRepository = CallbackGenreRepository(apiService: apiService)

        // When
        let result = await requestGenres(from: sut)

        // Assert
        let genres = try result.get()
        #expect(genres.count == 19)
        #expect(genres.first == .action)
    }

    @Test
    func failedRequestDeliversTheNetworkErrorUnchanged() async {
        // Given
        let apiService = CallbackAPIServiceStub(
            endpoint: endpoint,
            result: .failure(NetworkError.invalidResponse(statusCode: 401))
        )
        let sut: any ICallbackGenreRepository = CallbackGenreRepository(apiService: apiService)

        // When
        let result = await requestGenres(from: sut)

        // Assert
        #expect(throws: NetworkError.invalidResponse(statusCode: 401)) {
            try result.get()
        }
    }

    private func requestGenres(from repository: any ICallbackGenreRepository) async -> Result<[Genre], any Error> {
        await withCheckedContinuation { continuation in
            repository.movieGenres { result in
                continuation.resume(returning: result)
            }
        }
    }
}
