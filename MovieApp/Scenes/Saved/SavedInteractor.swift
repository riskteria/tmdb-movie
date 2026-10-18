protocol ISavedInteractor {
    // Returns when the calling task is cancelled.
    func observeSavedMovies(request: SavedModel.ObserveSavedMovies.Request) async
    func removeMovie(request: SavedModel.RemoveMovie.Request) async
}

final class SavedInteractor {
    private let presenter: any ISavedPresenter
    private let worker: any ISavedWorker

    init(presenter: any ISavedPresenter, worker: any ISavedWorker) {
        self.presenter = presenter
        self.worker = worker
    }
}

// MARK: - ISavedInteractor
extension SavedInteractor: ISavedInteractor {
    func observeSavedMovies(request: SavedModel.ObserveSavedMovies.Request) async {
        let isPersistent = worker.isPersistent
        for await savedMovies in await worker.observeSavedMovies() {
            presenter.presentSavedMovies(
                response: SavedModel.ObserveSavedMovies.Response(
                    savedMovies: savedMovies,
                    capacity: SavedMovie.capacity,
                    isPersistent: isPersistent
                )
            )
        }
    }

    func removeMovie(request: SavedModel.RemoveMovie.Request) async {
        let movie = request.movie
        do {
            try await worker.removeMovie(movie.id)
            presentRemoveMovie(movie, result: .success(()))
        } catch is CancellationError {
            return
        } catch {
            presentRemoveMovie(movie, result: .failure(error))
        }
    }
}

private extension SavedInteractor {
    func presentRemoveMovie(_ movie: Movie, result: Result<Void, any Error>) {
        presenter.presentRemoveMovie(response: SavedModel.RemoveMovie.Response(movie: movie, result: result))
    }
}
