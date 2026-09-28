protocol IHomeInteractor {
    func loadHome(request: HomeModel.LoadHome.Request) async
}

final class HomeInteractor {
    private static let continueWatchingLimit = 10

    private let presenter: any IHomePresenter
    private let worker: any IHomeWorker

    init(presenter: any IHomePresenter, worker: any IHomeWorker) {
        self.presenter = presenter
        self.worker = worker
    }
}

// MARK: - IHomeInteractor
extension HomeInteractor: IHomeInteractor {
    // Sections load concurrently and keep their own outcome, so one failed row doesn't blank the screen.
    func loadHome(request: HomeModel.LoadHome.Request) async {
        // Local copies, so the `async let` child tasks capture Sendable values rather than main-actor state.
        let homeWorker = worker
        let limit = Self.continueWatchingLimit

        async let trending = Result { try await homeWorker.fetchTrendingMovies(window: .day) }
        async let continueWatching = Result { try await homeWorker.fetchContinueWatching(limit: limit) }
        async let popular = Result { try await homeWorker.fetchMovies(in: .popular, page: 1) }
        async let topRated = Result { try await homeWorker.fetchMovies(in: .topRated, page: 1) }
        async let upcoming = Result { try await homeWorker.fetchMovies(in: .upcoming, page: 1) }
        async let genres = Result { try await homeWorker.fetchGenres() }

        let response = HomeModel.LoadHome.Response(
            trending: await trending,
            continueWatching: await continueWatching,
            popular: await popular,
            topRated: await topRated,
            upcoming: await upcoming,
            genres: await genres
        )
        guard !Task.isCancelled else { return }
        presenter.presentHome(response: response)
    }
}
