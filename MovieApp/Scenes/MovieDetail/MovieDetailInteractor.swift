protocol IMovieDetailInteractor {
    func loadDetails(request: MovieDetailModel.LoadDetails.Request) async
}

// A Week 1 stub: the header and overview. Watch, Save, cast, videos and More Like This follow.
final class MovieDetailInteractor {
    private let movie: Movie
    private let presenter: any IMovieDetailPresenter
    private let worker: any IMovieDetailWorker

    init(movie: Movie, presenter: any IMovieDetailPresenter, worker: any IMovieDetailWorker) {
        self.movie = movie
        self.presenter = presenter
        self.worker = worker
    }
}

// MARK: - IMovieDetailInteractor
extension MovieDetailInteractor: IMovieDetailInteractor {
    // Presents the movie it was opened with first, so the zoom transition lands on a filled header.
    func loadDetails(request: MovieDetailModel.LoadDetails.Request) async {
        present(details: nil)
        do {
            let details = try await worker.fetchDetails(movieID: movie.id)
            present(details: .success(details))
        } catch is CancellationError {
            return
        } catch {
            present(details: .failure(error))
        }
    }
}

private extension MovieDetailInteractor {
    func present(details: Result<MovieDetails, any Error>?) {
        presenter.presentDetails(response: MovieDetailModel.LoadDetails.Response(movie: movie, details: details))
    }
}
