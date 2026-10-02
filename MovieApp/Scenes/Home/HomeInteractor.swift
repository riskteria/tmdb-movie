protocol IHomeInteractor {
    func loadHome(request: HomeModel.LoadHome.Request) async
}

final class HomeInteractor {
    private let continueWatchingLimit = 10

    private let presenter: any IHomePresenter
    private let worker: any IHomeWorker

    init(presenter: any IHomePresenter, worker: any IHomeWorker) {
        self.presenter = presenter
        self.worker = worker
    }
}

// MARK: - IHomeInteractor
extension HomeInteractor: IHomeInteractor {
    func loadHome(request: HomeModel.LoadHome.Request) async {
        let homeWorker = worker
        let limit = continueWatchingLimit

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
