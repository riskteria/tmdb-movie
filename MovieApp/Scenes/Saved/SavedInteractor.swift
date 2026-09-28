protocol ISavedInteractor {
    // Returns when the calling task is cancelled.
    func observeSavedMovies(request: SavedModel.ObserveSavedMovies.Request) async
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
        for await savedMovies in await worker.observeSavedMovies() {
            presenter.presentSavedMovies(
                response: SavedModel.ObserveSavedMovies.Response(
                    savedMovies: savedMovies,
                    capacity: SavedMovie.capacity
                )
            )
        }
    }
}
