@testable import MovieApp
import Testing

struct MovieDetailWorkerTests {
    @Test
    func fetchDetailsReturnsDetailsForMovie() async throws {
        // Given
        let details = MovieDetails.fixture(movie: .fixture(id: 7))
        let repository = MovieRepositoryStub(detailsByID: [7: details])
        let sut = MovieDetailWorker(movieRepository: repository)

        // When
        let result = try await sut.fetchDetails(movieID: 7)

        // Assert
        #expect(result == details)
        #expect(repository.calls == [.details(7)])
    }
}
