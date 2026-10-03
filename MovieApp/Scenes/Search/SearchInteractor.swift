protocol ISearchInteractor {
    func loadGenres(request: SearchModel.LoadGenres.Request) async
}

final class SearchInteractor {
    private let presenter: any ISearchPresenter
    private let worker: any ISearchWorker

    init(presenter: any ISearchPresenter, worker: any ISearchWorker) {
        self.presenter = presenter
        self.worker = worker
    }
}

// MARK: - ISearchInteractor
extension SearchInteractor: ISearchInteractor {
    func loadGenres(request: SearchModel.LoadGenres.Request) async {
        do {
            let genres = try await worker.fetchGenres()
            presenter.presentGenres(response: SearchModel.LoadGenres.Response(result: .success(genres)))
        } catch is CancellationError {
            return
        } catch {
            presenter.presentGenres(response: SearchModel.LoadGenres.Response(result: .failure(error)))
        }
    }
}
