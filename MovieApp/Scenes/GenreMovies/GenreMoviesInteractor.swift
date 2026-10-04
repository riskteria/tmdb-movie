protocol IGenreMoviesInteractor {
    func loadNextPage(request: GenreMoviesModel.LoadNextPage.Request) async
    func refreshMovies(request: GenreMoviesModel.RefreshMovies.Request) async
}

final class GenreMoviesInteractor {
    private let genreID: Genre.ID
    private let presenter: any IGenreMoviesPresenter
    private let worker: any IGenreMoviesWorker
    private var movies: [Movie] = []
    private var nextPage: Int? = 1

    init(genreID: Genre.ID, presenter: any IGenreMoviesPresenter, worker: any IGenreMoviesWorker) {
        self.genreID = genreID
        self.presenter = presenter
        self.worker = worker
    }
}

// MARK: - IGenreMoviesInteractor
extension GenreMoviesInteractor: IGenreMoviesInteractor {
    func loadNextPage(request: GenreMoviesModel.LoadNextPage.Request) async {
        guard let pageNumber = nextPage else { return }
        presentMovies(status: .loading)
        await loadPage(pageNumber)
    }

    func refreshMovies(request: GenreMoviesModel.RefreshMovies.Request) async {
        await loadPage(1)
    }
}

private extension GenreMoviesInteractor {
    func loadPage(_ pageNumber: Int) async {
        do {
            let page = try await worker.fetchMovies(genreID: genreID, page: pageNumber)
            if pageNumber == 1 {
                movies = []
            }
            appendNewMovies(page.items)
            nextPage = page.hasNextPage ? pageNumber + 1 : nil
            presentMovies(status: .loaded)
        } catch is CancellationError {
            return
        } catch {
            presentMovies(status: .failed)
        }
    }

    func appendNewMovies(_ newMovies: [Movie]) {
        let shownIDs = Set(movies.map(\.id))
        movies += newMovies.filter { !shownIDs.contains($0.id) }
    }

    func presentMovies(status: GenreMoviesModel.LoadStatus) {
        presenter.presentMovies(response: GenreMoviesModel.LoadNextPage.Response(movies: movies, status: status))
    }
}
