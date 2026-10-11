protocol ISearchInteractor {
    func loadGenres(request: SearchModel.LoadGenres.Request) async
}

protocol ISearchCallbackInteractor {
    func loadGenresUsingCallback(request: SearchModel.LoadGenres.Request) async
}

final class SearchInteractor {
    private let presenter: any ISearchPresenter
    private let worker: any ISearchWorker
    private let callbackWorker: any ISearchCallbackWorker

    init(presenter: any ISearchPresenter, worker: any ISearchWorker, callbackWorker: any ISearchCallbackWorker) {
        self.presenter = presenter
        self.worker = worker
        self.callbackWorker = callbackWorker
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

// MARK: - ISearchCallbackInteractor
extension SearchInteractor: ISearchCallbackInteractor {
    func loadGenresUsingCallback(request: SearchModel.LoadGenres.Request) async {
        do {
            let genres: [Genre] = try await withCheckedThrowingContinuation { continuation in
                callbackWorker.fetchGenres { result in
                    continuation.resume(with: result)
                }
            }
            presenter.presentGenres(response: SearchModel.LoadGenres.Response(result: .success(genres)))
        } catch is CancellationError {
            return
        } catch {
            presenter.presentGenres(response: SearchModel.LoadGenres.Response(result: .failure(error)))
        }
    }
}
