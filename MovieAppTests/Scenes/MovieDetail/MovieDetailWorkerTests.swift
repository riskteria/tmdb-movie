@testable import MovieApp
import Testing

struct MovieDetailWorkerTests {
    @Test
    func fetchDetailsReturnsDetailsForMovie() async throws {
        // Given
        let details = MovieDetails.fixture(movie: .fixture(id: 7))
        let repository = MovieRepositoryStub(detailsByID: [7: details])
        let sut: any IMovieDetailWorker = MovieDetailWorker(movieRepository: repository)

        // When
        let result = try await sut.fetchDetails(movieID: 7)

        // Assert
        #expect(result == details)
        #expect(repository.calls == [.details(7)])
    }

    @Test
    func fetchDetailsRethrowsRepositoryError() async {
        // Given
        let sut: any IMovieDetailWorker = MovieDetailWorker(movieRepository: MovieRepositoryStub())

        // When & Assert
        await #expect(throws: StubError.failed) {
            try await sut.fetchDetails(movieID: 7)
        }
    }
}
