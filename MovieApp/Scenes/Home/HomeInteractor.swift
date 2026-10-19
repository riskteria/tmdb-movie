protocol IHomeInteractor {
    func loadHome(request: HomeModel.LoadHome.Request) async
}

final class HomeInteractor {
    private struct Sections {
        let trending: Result<[Movie], any Error>
        let popular: Result<Page<Movie>, any Error>
        let topRated: Result<Page<Movie>, any Error>
        let upcoming: Result<Page<Movie>, any Error>
        let genres: Result<[Genre], any Error>
    }

    private let continueWatchingLimit = 10

    private let presenter: any IHomePresenter
    private let worker: any IHomeWorker
    private var sections: Sections?
    private var continueWatching: Result<[ContinueWatchingItem], any Error>?

    init(presenter: any IHomePresenter, worker: any IHomeWorker) {
        self.presenter = presenter
        self.worker = worker
    }
}

// MARK: - IHomeInteractor
extension HomeInteractor: IHomeInteractor {
    func loadHome(request: HomeModel.LoadHome.Request) async {
        sections = nil
        continueWatching = nil
        async let sectionsLoad: Void = loadSections()
        async let continueWatchingObservation: Void = observeContinueWatching()
        _ = await (sectionsLoad, continueWatchingObservation)
    }
}

private extension HomeInteractor {
    func loadSections() async {
        let homeWorker = worker

        async let trending = Result { try await homeWorker.fetchTrendingMovies(window: .day) }
        async let popular = Result { try await homeWorker.fetchMovies(in: .popular, page: 1) }
        async let topRated = Result { try await homeWorker.fetchMovies(in: .topRated, page: 1) }
        async let upcoming = Result { try await homeWorker.fetchMovies(in: .upcoming, page: 1) }
        async let genres = Result { try await homeWorker.fetchGenres() }

        let loaded = Sections(
            trending: await trending,
            popular: await popular,
            topRated: await topRated,
            upcoming: await upcoming,
            genres: await genres
        )
        guard !Task.isCancelled else { return }
        sections = loaded
        presentHomeIfReady()
    }

    func observeContinueWatching() async {
        let homeWorker = worker
        let limit = continueWatchingLimit
        for await state in await homeWorker.observeWatchProgress() {
            let items: Result<[ContinueWatchingItem], any Error>
            switch state {
            case .signedOut:
                items = .success([])
            case .signedIn:
                items = await Result { try await homeWorker.fetchContinueWatching(limit: limit) }
            }
            guard !Task.isCancelled else { return }
            continueWatching = items
            presentHomeIfReady()
        }
    }

    func presentHomeIfReady() {
        guard let sections, let continueWatching else { return }
        presenter.presentHome(
            response: HomeModel.LoadHome.Response(
                trending: sections.trending,
                continueWatching: continueWatching,
                popular: sections.popular,
                topRated: sections.topRated,
                upcoming: sections.upcoming,
                genres: sections.genres
            )
        )
    }
}
