protocol IMovieDetailInteractor {
    func loadDetails(request: MovieDetailModel.LoadDetails.Request) async
    func observeSavedState(request: MovieDetailModel.ObserveSavedState.Request) async
    func toggleSave(request: MovieDetailModel.ToggleSave.Request) async
    func watch(request: MovieDetailModel.Watch.Request) async
}

final class MovieDetailInteractor {
    private let movie: Movie
    private let presenter: any IMovieDetailPresenter
    private let worker: any IMovieDetailWorker
    private var isSaved = false
    private var isSavedStateKnown = false
    private var isTogglingSave = false

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

    func observeSavedState(request: MovieDetailModel.ObserveSavedState.Request) async {
        for await savedMovies in await worker.observeSavedMovies() {
            let isSaved = savedMovies.contains { $0.id == movie.id }
            guard !isSavedStateKnown || isSaved != self.isSaved else { continue }
            isSavedStateKnown = true
            self.isSaved = isSaved
            presenter.presentSavedState(response: MovieDetailModel.ObserveSavedState.Response(isSaved: isSaved))
        }
    }

    func toggleSave(request: MovieDetailModel.ToggleSave.Request) async {
        guard isSavedStateKnown, !isTogglingSave else { return }
        isTogglingSave = true
        defer { isTogglingSave = false }
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
                response: MovieDetailModel.ToggleSave.Response(action: isSaved ? .remove : .save, movie: movie)
            )
        }
    }

    func watch(request: MovieDetailModel.Watch.Request) async {
        do {
            try await worker.startWatching(movieID: movie.id, video: request.video)
            try Task.checkCancellation()
            presentWatch(result: .success(request.video))
        } catch is CancellationError {
            return
        } catch {
            presentWatch(result: .failure(error))
        }
    }
}

private extension MovieDetailInteractor {
    func present(details: Result<MovieDetails, any Error>?) {
        presenter.presentDetails(response: MovieDetailModel.LoadDetails.Response(movie: movie, details: details))
    }

    func presentWatch(result: Result<Video, any Error>) {
        presenter.presentWatch(response: MovieDetailModel.Watch.Response(movie: movie, result: result))
    }
}
