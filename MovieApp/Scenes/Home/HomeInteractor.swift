protocol IHomeInteractor {
    func loadHome(request: HomeModel.LoadHome.Request) async
    func observeSavedState(request: HomeModel.ObserveSavedState.Request) async
    func toggleSave(request: HomeModel.ToggleSave.Request) async
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
    private var savedState: AccountScoped<Set<Movie.ID>>?
    private var togglingMovieIDs: Set<Movie.ID> = []

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

    func observeSavedState(request: HomeModel.ObserveSavedState.Request) async {
        for await state in await worker.observeSavedMovies() {
            let savedState: AccountScoped<Set<Movie.ID>> = switch state {
            case .signedOut:
                .signedOut
            case .signedIn(let savedMovies):
                .signedIn(Set(savedMovies.map(\.id)))
            }
            guard savedState != self.savedState else { continue }
            self.savedState = savedState
            presenter.presentSavedState(response: HomeModel.ObserveSavedState.Response(savedState: savedState))
        }
    }

    func toggleSave(request: HomeModel.ToggleSave.Request) async {
        let movie = request.movie
        guard case .signedIn(let savedMovieIDs) = savedState, !togglingMovieIDs.contains(movie.id) else { return }
        togglingMovieIDs.insert(movie.id)
        defer { togglingMovieIDs.remove(movie.id) }
        let isSaved = savedMovieIDs.contains(movie.id)
        do {
            if isSaved {
                try await worker.removeMovie(movie.id)
            } else {
                try await worker.saveMovie(movie)
            }
        } catch is CancellationError {
            return
        } catch {
            presenter.presentToggleSave(
                response: HomeModel.ToggleSave.Response(action: isSaved ? .remove : .save, movie: movie)
            )
        }
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
