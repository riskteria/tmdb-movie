@testable import MovieApp
import Testing

struct GenreMoviesWorkerTests {
    @Test
    func fetchMoviesAsksForThatGenresPage() async throws {
        // Given
        let movies = [Movie.fixture(id: 1), .fixture(id: 2)]
        let repository = MovieRepositoryStub(moviePage: .fixture(movies))
        let sut = GenreMoviesWorker(movieRepository: repository)

        // When
        let page = try await sut.fetchMovies(genreID: 28, page: 3)

        // Assert
        #expect(page.items == movies)
        #expect(repository.calls == [.discover([28], page: 3)])
    }
}
