@testable import MovieApp
import Testing

struct GenreMoviesWorkerTests {
    @Test
    func fetchMoviesAsksForThatGenresPage() async throws {
        // Given
        let movies = [Movie.fixture(id: 1), .fixture(id: 2)]
        let repository = MovieRepositoryStub(discover: .success(.fixture(movies)))
        let sut: any IGenreMoviesWorker = GenreMoviesWorker(movieRepository: repository)

        // When
        let page = try await sut.fetchMovies(genreID: 28, page: 3)

        // Assert
        #expect(page.items == movies)
        #expect(repository.calls == [.discover([28], page: 3)])
    }

    @Test
    func fetchMoviesRethrowsRepositoryError() async {
        // Given
        let repository = MovieRepositoryStub(discover: .failure(StubError.failed))
        let sut: any IGenreMoviesWorker = GenreMoviesWorker(movieRepository: repository)

        // When & Assert
        await #expect(throws: StubError.failed) {
            try await sut.fetchMovies(genreID: 28, page: 1)
        }
    }
}
