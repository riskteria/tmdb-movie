@testable import MovieApp
import Testing

@MainActor
struct HomeInteractorTests {
    private let presenter = HomePresenterSpy()

    @Test
    func loadHomePresentsEverySection() async throws {
        // Given
        let trending = [Movie.fixture(id: 1)]
        let page = Page.fixture([.fixture(id: 2)])
        let continueWatching = [
            ContinueWatchingItem(progress: .fixture(contentID: 3), details: .fixture(movie: .fixture(id: 3)))
        ]
        let sut = makeSUT(
            trending: .success(trending),
            continueWatching: .success(continueWatching),
            movies: .success(page),
            genres: .success([.drama])
        )

        // When
        await sut.loadHome(request: HomeModel.LoadHome.Request())

        // Assert
        let response = try #require(presenter.responses.first)
        #expect(try response.trending.get() == trending)
        #expect(try response.continueWatching.get() == continueWatching)
        #expect(try response.popular.get() == page)
        #expect(try response.topRated.get() == page)
        #expect(try response.upcoming.get() == page)
        #expect(try response.genres.get() == [.drama])
    }

    @Test
    func loadHomeKeepsOtherSectionsWhenOneFails() async throws {
        // Given
        let page = Page.fixture([.fixture(id: 2)])
        let sut = makeSUT(trending: .failure(StubError.failed), movies: .success(page))

        // When
        await sut.loadHome(request: HomeModel.LoadHome.Request())

        // Assert
        let response = try #require(presenter.responses.first)
        #expect(throws: StubError.failed) {
            try response.trending.get()
        }
        #expect(try response.popular.get() == page)
    }

    @Test
    func loadHomeWaitsForContinueWatchingBeforePresenting() async {
        // Given
        let sut = makeSUT(watchProgressStates: [])

        // When
        await sut.loadHome(request: HomeModel.LoadHome.Request())

        // Assert
        #expect(presenter.responses.isEmpty)
    }

    @Test
    func signedOutPresentsHomeWithoutContinueWatching() async throws {
        // Given
        let sut = makeSUT(continueWatching: .failure(StubError.failed), watchProgressStates: [.signedOut])

        // When
        await sut.loadHome(request: HomeModel.LoadHome.Request())

        // Assert
        let response = try #require(presenter.responses.first)
        #expect(try response.continueWatching.get().isEmpty)
    }

    @Test
    func watchProgressChangePresentsHomeAgain() async {
        // Given
        let sut = makeSUT(watchProgressStates: [.signedIn([]), .signedIn([])])

        // When
        await sut.loadHome(request: HomeModel.LoadHome.Request())

        // Assert
        #expect(presenter.responses.count == 2)
    }

    @Test(.timeLimit(.minutes(1)))
    func loadHomeReturnsWhenCancelled() async {
        // Given
        let sut = makeSUT(watchProgressStates: [], finishesWatchProgress: false)
        let loadHome = Task { await sut.loadHome(request: HomeModel.LoadHome.Request()) }

        // When
        loadHome.cancel()
        await loadHome.value

        // Assert
        #expect(presenter.responses.isEmpty)
    }

    private func makeSUT(
        trending: Result<[Movie], any Error> = .success([]),
        continueWatching: Result<[ContinueWatchingItem], any Error> = .success([]),
        movies: Result<Page<Movie>, any Error> = .success(.fixture([])),
        genres: Result<[Genre], any Error> = .success([]),
        watchProgressStates: [AccountScoped<[WatchProgress]>] = [.signedIn([])],
        finishesWatchProgress: Bool = true
    ) -> any IHomeInteractor {
        HomeInteractor(
            presenter: presenter,
            worker: HomeWorkerStub(
                trending: trending,
                continueWatching: continueWatching,
                movies: movies,
                genres: genres,
                watchProgressStates: watchProgressStates,
                finishesWatchProgress: finishesWatchProgress
            )
        )
    }
}

@MainActor
private final class HomePresenterSpy: IHomePresenter {
    private(set) var responses: [HomeModel.LoadHome.Response] = []

    func presentHome(response: HomeModel.LoadHome.Response) {
        responses.append(response)
    }

    func presentSavedState(response: HomeModel.ObserveSavedState.Response) {
        Issue.record("Unexpected call to presentSavedState(response:)")
    }

    func presentToggleSave(response: HomeModel.ToggleSave.Response) {
        Issue.record("Unexpected call to presentToggleSave(response:)")
    }
}

private struct HomeWorkerStub: IHomeWorker {
    let trending: Result<[Movie], any Error>
    let continueWatching: Result<[ContinueWatchingItem], any Error>
    let movies: Result<Page<Movie>, any Error>
    let genres: Result<[Genre], any Error>
    let watchProgressStates: [AccountScoped<[WatchProgress]>]
    let finishesWatchProgress: Bool

    func fetchTrendingMovies(window: TrendingWindow) async throws -> [Movie] {
        try trending.get()
    }

    func fetchMovies(in category: MovieCategory, page: Int) async throws -> Page<Movie> {
        try movies.get()
    }

    func fetchContinueWatching(limit: Int) async throws -> [ContinueWatchingItem] {
        try continueWatching.get()
    }

    func fetchGenres() async throws -> [Genre] {
        try genres.get()
    }

    func observeWatchProgress() async -> AsyncStream<AccountScoped<[WatchProgress]>> {
        AsyncStream { continuation in
            watchProgressStates.forEach { state in continuation.yield(state) }
            if finishesWatchProgress {
                continuation.finish()
            }
        }
    }

    func observeSavedMovies() async -> AsyncStream<AccountScoped<[SavedMovie]>> {
        Issue.record("Unexpected call to observeSavedMovies()")
        return AsyncStream { continuation in continuation.finish() }
    }

    func saveMovie(_ movie: Movie) async throws {
        Issue.record("Unexpected call to saveMovie(_:)")
    }

    func removeMovie(_ movieID: Movie.ID) async throws {
        Issue.record("Unexpected call to removeMovie(_:)")
    }
}
