protocol IDiscoverInteractor {
    func loadGenres(request: DiscoverModel.LoadGenres.Request) async
}

final class DiscoverInteractor {
    private let presenter: any IDiscoverPresenter
    private let worker: any IDiscoverWorker

    init(presenter: any IDiscoverPresenter, worker: any IDiscoverWorker) {
        self.presenter = presenter
        self.worker = worker
    }
}

// MARK: - IDiscoverInteractor
extension DiscoverInteractor: IDiscoverInteractor {
    func loadGenres(request: DiscoverModel.LoadGenres.Request) async {
        do {
            let genres = try await worker.fetchGenres()
            presenter.presentGenres(response: DiscoverModel.LoadGenres.Response(result: .success(genres)))
        } catch is CancellationError {
            return
        } catch {
            presenter.presentGenres(response: DiscoverModel.LoadGenres.Response(result: .failure(error)))
        }
    }
}
