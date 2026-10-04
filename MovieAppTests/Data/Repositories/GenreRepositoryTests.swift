@testable import MovieApp
import Testing

struct GenreRepositoryTests {
    @Test
    func loadGenresSuccess() async throws {
        // Given
        let json = try JSONFixture.named(.movieGenres)
        let apiService = APIServiceStub(
            endpoint: .movieGenres(parameters: .init(language: "en-US")),
            result: .success(json)
        )
        let sut = GenreRepository(apiService: apiService)

        // When
        let genres = try await sut.movieGenres()

        // Assert
        #expect(genres.first == .action)
    }
    
    @Test
    func loadGenresFailureInvalidResponse() async throws {
        // Given
        let apiService = APIServiceStub(
            endpoint: .movieGenres(parameters: .init(language: "en-US")),
            result: .failure(NetworkError.invalidResponse(statusCode: 500))
        )
        let sut = GenreRepository(apiService: apiService)
        
        // Assert
        await #expect(throws: NetworkError.invalidResponse(statusCode: 500)) {
            try await sut.movieGenres()
        }
    }
}
