@testable import MovieApp
import Testing

@MainActor
struct MovieDetailInteractorTests {
    private let presenter = MovieDetailPresenterSpy()
    private let movie = Movie.fixture(id: 7)

    @Test
    func loadDetailsPresentsMovieBeforeDetails() async throws {
        // Given
        let details = MovieDetails.fixture(movie: movie)
        let sut = makeSUT(result: .success(details))

        // When
        await sut.loadDetails(request: MovieDetailModel.LoadDetails.Request())

        // Assert
        #expect(presenter.responses.map(\.movie) == [movie, movie])
        #expect(presenter.responses.first?.details == nil)
        let loaded = try #require(presenter.responses.last?.details)
        #expect(try loaded.get() == details)
    }

    @Test
    func loadDetailsPresentsFailure() async throws {
        // Given
        let sut = makeSUT(result: .failure(StubError.failed))

        // When
        await sut.loadDetails(request: MovieDetailModel.LoadDetails.Request())

        // Assert
        let loaded = try #require(presenter.responses.last?.details)
        #expect(throws: StubError.failed) {
            try loaded.get()
        }
    }

    @Test
    func loadDetailsPresentsOnlyTheMovieWhenCancelled() async {
        // Given
        let sut = makeSUT(result: .failure(CancellationError()))

        // When
        await sut.loadDetails(request: MovieDetailModel.LoadDetails.Request())

        // Assert
        #expect(presenter.responses.count == 1)
    }

    private func makeSUT(result: Result<MovieDetails, any Error>) -> any IMovieDetailInteractor {
        MovieDetailInteractor(
            movie: movie,
            presenter: presenter,
            worker: MovieDetailWorkerStub(result: result)
        )
    }
}

@MainActor
private final class MovieDetailPresenterSpy: IMovieDetailPresenter {
    private(set) var responses: [MovieDetailModel.LoadDetails.Response] = []

    func presentDetails(response: MovieDetailModel.LoadDetails.Response) {
        responses.append(response)
    }
}

private struct MovieDetailWorkerStub: IMovieDetailWorker {
    let result: Result<MovieDetails, any Error>

    func fetchDetails(movieID: Movie.ID) async throws -> MovieDetails {
        try result.get()
    }
}
