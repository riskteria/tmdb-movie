@testable import MovieApp
import Testing

struct GenreRepositoryTests {
    private let endpoint = TMDBEndpoint.movieGenres(parameters: .init(language: "en-US"))

    @Test
    func movieGenresMapsEveryGenre() async throws {
        // Given
        let apiService = APIServiceStub(
            endpoint: endpoint,
            result: .success(try JSONFixture.named(.movieGenres))
        )
        let sut: any IGenreRepository = GenreRepository(apiService: apiService)

        // When
        let genres = try await sut.movieGenres()

        // Assert
        #expect(genres.count == 19)
        #expect(genres.first == .action)
    }

    @Test
    func failedRequestThrowsTheNetworkErrorUnchanged() async {
        // Given
        let apiService = APIServiceStub(
            endpoint: endpoint,
            result: .failure(NetworkError.invalidResponse(statusCode: 401))
        )
        let sut: any IGenreRepository = GenreRepository(apiService: apiService)

        // When & Assert
        await #expect(throws: NetworkError.invalidResponse(statusCode: 401)) {
            try await sut.movieGenres()
        }
    }
}
