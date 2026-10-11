@testable import MovieApp
import Testing

struct SearchWorkerTests {
    @Test
    func fetchGenresReturnsMovieGenres() async throws {
        // Given
        let genres = [Genre.scienceFiction, Genre.drama]
        let repository = GenreRepositoryStub(result: .success(genres))
        let sut: any ISearchWorker = SearchWorker(genreRepository: repository)

        // When
        let result = try await sut.fetchGenres()

        // Assert
        #expect(result == genres)
        #expect(await repository.calls == [.movieGenres])
    }

    @Test
    func fetchGenresRethrowsRepositoryError() async {
        // Given
        let sut: any ISearchWorker = SearchWorker(
            genreRepository: GenreRepositoryStub(result: .failure(StubError.failed))
        )

        // When & Assert
        await #expect(throws: StubError.failed) {
            try await sut.fetchGenres()
        }
    }
}
