@testable import MovieApp
import Testing

struct SearchWorkerTests {
    @Test
    func fetchGenresReturnsMovieGenres() async throws {
        // Given
        let genres = [Genre.scienceFiction, Genre.drama]
        let sut = SearchWorker(genreRepository: GenreRepositoryStub(result: .success(genres)))

        // When
        let result = try await sut.fetchGenres()

        // Assert
        #expect(result == genres)
    }

    @Test
    func fetchGenresRethrowsRepositoryError() async {
        // Given
        let sut = SearchWorker(genreRepository: GenreRepositoryStub(result: .failure(StubError.failed)))

        // When & Assert
        await #expect(throws: StubError.failed) {
            try await sut.fetchGenres()
        }
    }
}
