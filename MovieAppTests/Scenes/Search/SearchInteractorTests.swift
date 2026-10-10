@testable import MovieApp
import Testing

@MainActor
struct SearchInteractorTests {
    private let presenter = SearchPresenterSpy()

    @Test
    func loadGenresPresentsFetchedGenres() async throws {
        // Given
        let genres = [Genre.scienceFiction, Genre.drama]
        let sut: any ISearchInteractor = SearchInteractor(
            presenter: presenter,
            worker: SearchWorkerStub(result: .success(genres))
        )

        // When
        await sut.loadGenres(request: SearchModel.LoadGenres.Request())

        // Assert
        let response = try #require(presenter.responses.first)
        #expect(try response.result.get() == genres)
    }

    @Test
    func loadGenresPresentsFailure() async throws {
        // Given
        let sut: any ISearchInteractor = SearchInteractor(
            presenter: presenter,
            worker: SearchWorkerStub(result: .failure(StubError.failed))
        )

        // When
        await sut.loadGenres(request: SearchModel.LoadGenres.Request())

        // Assert
        let response = try #require(presenter.responses.first)
        #expect(throws: StubError.failed) {
            try response.result.get()
        }
    }

    @Test
    func loadGenresPresentsNothingWhenCancelled() async {
        // Given
        let sut: any ISearchInteractor = SearchInteractor(
            presenter: presenter,
            worker: SearchWorkerStub(result: .failure(CancellationError()))
        )

        // When
        await sut.loadGenres(request: SearchModel.LoadGenres.Request())

        // Assert
        #expect(presenter.responses.isEmpty)
    }
}

@MainActor
private final class SearchPresenterSpy: ISearchPresenter {
    private(set) var responses: [SearchModel.LoadGenres.Response] = []

    func presentGenres(response: SearchModel.LoadGenres.Response) {
        responses.append(response)
    }
}

private struct SearchWorkerStub: ISearchWorker {
    let result: Result<[Genre], any Error>

    func fetchGenres() async throws -> [Genre] {
        try result.get()
    }
}
