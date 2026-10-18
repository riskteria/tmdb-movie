@testable import MovieApp
import Testing

@MainActor
struct GenreMoviesInteractorTests {
    private let presenter = GenreMoviesPresenterSpy()

    @Test
    func loadNextPageRequestsTheFollowingPage() async {
        // Given
        let worker = makeTwoPageWorker()
        let sut = makeSUT(worker: worker)
        await sut.loadNextPage(request: .init())

        // When
        await sut.loadNextPage(request: .init())

        // Assert
        #expect(await worker.requestedPages == [1, 2])
    }

    @Test
    func loadNextPagePresentsLoadingBeforeEachLoadedPage() async {
        // Given
        let sut = makeSUT(worker: makeTwoPageWorker())
        await sut.loadNextPage(request: .init())

        // When
        await sut.loadNextPage(request: .init())

        // Assert
        #expect(presenter.presentedStatuses == [.loading, .loaded, .loading, .loaded])
    }

    @Test
    func loadNextPageAppendsTheNewPageToEarlierMovies() async {
        // Given
        let sut = makeSUT(worker: makeTwoPageWorker())
        await sut.loadNextPage(request: .init())

        // When
        await sut.loadNextPage(request: .init())

        // Assert
        #expect(presenter.lastPresentedMovieIDs == [1, 2, 3])
    }

    @Test
    func loadNextPageAsksForTheScenesGenre() async {
        // Given
        let worker = makeTwoPageWorker()
        let sut = makeSUT(worker: worker)

        // When
        await sut.loadNextPage(request: .init())

        // Assert
        #expect(await worker.requestedGenreIDs == [28])
    }

    @Test
    func loadNextPageAfterTheLastPageRequestsNothing() async {
        // Given
        let worker = GenreMoviesWorkerStub(resultsByPage: [
            1: .success(makePage(number: 1, totalPages: 1, movieIDs: [1]))
        ])
        let sut = makeSUT(worker: worker)
        await sut.loadNextPage(request: .init())

        // When
        await sut.loadNextPage(request: .init())

        // Assert
        #expect(await worker.requestedPages == [1])
    }

    @Test
    func failedPageIsRequestedAgainOnTheNextLoad() async {
        // Given
        let worker = makeFirstPageOnlyWorker()
        let sut = makeSUT(worker: worker)
        await sut.loadNextPage(request: .init())
        await sut.loadNextPage(request: .init())

        // When
        await sut.loadNextPage(request: .init())

        // Assert
        #expect(await worker.requestedPages == [1, 2, 2])
    }

    @Test
    func failedLaterPagePresentsFailureWithEarlierMovies() async throws {
        // Given
        let sut = makeSUT(worker: makeFirstPageOnlyWorker())
        await sut.loadNextPage(request: .init())

        // When
        await sut.loadNextPage(request: .init())

        // Assert
        let response = try #require(presenter.responses.last)
        #expect(response.status == .failed)
        #expect(response.movies.map(\.id) == [1])
    }

    @Test
    func cancelledLoadPresentsNoFailure() async {
        // Given
        let worker = GenreMoviesWorkerStub(resultsByPage: [1: .failure(CancellationError())])
        let sut = makeSUT(worker: worker)

        // When
        await sut.loadNextPage(request: .init())

        // Assert
        #expect(presenter.presentedStatuses == [.loading])
    }

    @Test
    func movieRepeatedOnALaterPageIsShownOnce() async {
        // Given
        let worker = GenreMoviesWorkerStub(resultsByPage: [
            1: .success(makePage(number: 1, totalPages: 3, movieIDs: [1, 2])),
            2: .success(makePage(number: 2, totalPages: 3, movieIDs: [2, 3]))
        ])
        let sut = makeSUT(worker: worker)
        await sut.loadNextPage(request: .init())

        // When
        await sut.loadNextPage(request: .init())

        // Assert
        #expect(presenter.lastPresentedMovieIDs == [1, 2, 3])
    }

    @Test
    func refreshRequestsTheFirstPageAgain() async {
        // Given
        let worker = makeTwoPageWorker()
        let sut = makeSUT(worker: worker)
        await sut.loadNextPage(request: .init())
        await sut.loadNextPage(request: .init())

        // When
        await sut.refreshMovies(request: .init())

        // Assert
        #expect(await worker.requestedPages == [1, 2, 1])
    }

    @Test
    func refreshReplacesTheListWithTheFirstPage() async {
        // Given
        let worker = makeTwoPageWorker()
        let sut = makeSUT(worker: worker)
        await sut.loadNextPage(request: .init())
        await sut.loadNextPage(request: .init())
        await worker.setResult(.success(makePage(number: 1, totalPages: 3, movieIDs: [4])), forPage: 1)

        // When
        await sut.refreshMovies(request: .init())

        // Assert
        #expect(presenter.lastPresentedMovieIDs == [4])
    }

    @Test
    func refreshPresentsNoLoadingState() async {
        // Given
        let sut = makeSUT(worker: makeTwoPageWorker())
        await sut.loadNextPage(request: .init())

        // When
        await sut.refreshMovies(request: .init())

        // Assert
        #expect(presenter.presentedStatuses == [.loading, .loaded, .loaded])
    }

    @Test
    func failedRefreshKeepsTheMoviesOnScreen() async {
        // Given
        let worker = makeTwoPageWorker()
        let sut = makeSUT(worker: worker)
        await sut.loadNextPage(request: .init())
        await sut.loadNextPage(request: .init())
        await worker.setResult(.failure(StubError.failed), forPage: 1)

        // When
        await sut.refreshMovies(request: .init())

        // Assert
        #expect(presenter.lastPresentedMovieIDs == [1, 2, 3])
    }

    @Test
    func loadNextPageAfterRefreshRequestsPageTwo() async {
        // Given
        let worker = makeTwoPageWorker()
        let sut = makeSUT(worker: worker)
        await sut.loadNextPage(request: .init())
        await sut.loadNextPage(request: .init())
        await sut.refreshMovies(request: .init())

        // When
        await sut.loadNextPage(request: .init())

        // Assert
        #expect(await worker.requestedPages == [1, 2, 1, 2])
    }

    private func makeSUT(worker: any IGenreMoviesWorker) -> any IGenreMoviesInteractor {
        GenreMoviesInteractor(genreID: 28, presenter: presenter, worker: worker)
    }

    private func makeTwoPageWorker() -> GenreMoviesWorkerStub {
        GenreMoviesWorkerStub(resultsByPage: [
            1: .success(makePage(number: 1, totalPages: 3, movieIDs: [1, 2])),
            2: .success(makePage(number: 2, totalPages: 3, movieIDs: [3]))
        ])
    }

    private func makeFirstPageOnlyWorker() -> GenreMoviesWorkerStub {
        GenreMoviesWorkerStub(resultsByPage: [
            1: .success(makePage(number: 1, totalPages: 3, movieIDs: [1]))
        ])
    }

    private func makePage(number: Int, totalPages: Int, movieIDs: [Movie.ID]) -> Page<Movie> {
        Page(number: number, items: movieIDs.map { Movie.fixture(id: $0) }, totalPages: totalPages, totalResults: 60)
    }
}

@MainActor
private final class GenreMoviesPresenterSpy: IGenreMoviesPresenter {
    private(set) var responses: [GenreMoviesModel.LoadNextPage.Response] = []

    var presentedStatuses: [GenreMoviesModel.LoadStatus] {
        responses.map(\.status)
    }

    var lastPresentedMovieIDs: [Movie.ID] {
        responses.last?.movies.map(\.id) ?? []
    }

    func presentMovies(response: GenreMoviesModel.LoadNextPage.Response) {
        responses.append(response)
    }
}

private actor GenreMoviesWorkerStub {
    private var resultsByPage: [Int: Result<Page<Movie>, any Error>]
    private(set) var requestedPages: [Int] = []
    private(set) var requestedGenreIDs: [Genre.ID] = []

    init(resultsByPage: [Int: Result<Page<Movie>, any Error>]) {
        self.resultsByPage = resultsByPage
    }

    func setResult(_ result: Result<Page<Movie>, any Error>, forPage page: Int) {
        resultsByPage[page] = result
    }
}

// MARK: - IGenreMoviesWorker
extension GenreMoviesWorkerStub: IGenreMoviesWorker {
    func fetchMovies(genreID: Genre.ID, page: Int) async throws -> Page<Movie> {
        requestedGenreIDs.append(genreID)
        requestedPages.append(page)
        guard let result = resultsByPage[page] else { throw StubError.failed }
        return try result.get()
    }
}
