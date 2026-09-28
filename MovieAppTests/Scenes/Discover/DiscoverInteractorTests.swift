@testable import MovieApp
import Testing

@MainActor
struct DiscoverInteractorTests {
    private let presenter = DiscoverPresenterSpy()

    @Test
    func loadGenresPresentsFetchedGenres() async throws {
        // Given
        let genres = [Genre.scienceFiction, Genre.drama]
        let sut = DiscoverInteractor(
            presenter: presenter,
            worker: DiscoverWorkerStub(result: .success(genres))
        )

        // When
        await sut.loadGenres(request: DiscoverModel.LoadGenres.Request())

        // Assert
        let response = try #require(presenter.responses.first)
        #expect(try response.result.get() == genres)
    }

    @Test
    func loadGenresPresentsFailure() async throws {
        // Given
        let sut = DiscoverInteractor(
            presenter: presenter,
            worker: DiscoverWorkerStub(result: .failure(StubError.failed))
        )

        // When
        await sut.loadGenres(request: DiscoverModel.LoadGenres.Request())

        // Assert
        let response = try #require(presenter.responses.first)
        #expect(throws: StubError.failed) {
            try response.result.get()
        }
    }

    @Test
    func loadGenresPresentsNothingWhenCancelled() async {
        // Given
        let sut = DiscoverInteractor(
            presenter: presenter,
            worker: DiscoverWorkerStub(result: .failure(CancellationError()))
        )

        // When
        await sut.loadGenres(request: DiscoverModel.LoadGenres.Request())

        // Assert
        #expect(presenter.responses.isEmpty)
    }
}

@MainActor
private final class DiscoverPresenterSpy: IDiscoverPresenter {
    private(set) var responses: [DiscoverModel.LoadGenres.Response] = []

    func presentGenres(response: DiscoverModel.LoadGenres.Response) {
        responses.append(response)
    }
}

private struct DiscoverWorkerStub: IDiscoverWorker {
    let result: Result<[Genre], any Error>

    func fetchGenres() async throws -> [Genre] {
        try result.get()
    }
}
