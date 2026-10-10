@testable import MovieApp
import Synchronization
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
        #expect(worker.requestedPages == [1, 2])
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
    func failedPageIsRequestedAgainOnTheNextLoad() async {
        // Given
        let worker = GenreMoviesWorkerStub(resultsByPage: [
            1: .success(makePage(number: 1, totalPages: 3, movieIDs: [1]))
        ])
        let sut = makeSUT(worker: worker)
        await sut.loadNextPage(request: .init())
        await sut.loadNextPage(request: .init())

        // When
        await sut.loadNextPage(request: .init())

        // Assert
        #expect(worker.requestedPages == [1, 2, 2])
        #expect(presenter.presentedStatuses.last == .failed)
        #expect(presenter.lastPresentedMovieIDs == [1])
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
    func refreshStartsPagingAgainFromTheFirstPage() async {
        // Given
        let worker = makeTwoPageWorker()
        let sut = makeSUT(worker: worker)
        await sut.loadNextPage(request: .init())
        await sut.loadNextPage(request: .init())

        // When
        await sut.refreshMovies(request: .init())

        // Assert
        #expect(worker.requestedPages == [1, 2, 1])
        #expect(presenter.lastPresentedMovieIDs == [1, 2])
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

private final class GenreMoviesWorkerStub: IGenreMoviesWorker {
    private let resultsByPage: [Int: Result<Page<Movie>, any Error>]
    private let pageRequests = Mutex<[Int]>([])

    var requestedPages: [Int] {
        pageRequests.withLock { $0 }
    }

    init(resultsByPage: [Int: Result<Page<Movie>, any Error>]) {
        self.resultsByPage = resultsByPage
    }

    func fetchMovies(genreID: Genre.ID, page: Int) async throws -> Page<Movie> {
        pageRequests.withLock { $0.append(page) }
        guard let result = resultsByPage[page] else { throw StubError.failed }
        return try result.get()
    }
}
