import UIKit

enum SearchSceneFactory {
    static func make(
        genreRepository: any IGenreRepository,
        callbackGenreRepository: any ICallbackGenreRepository,
        onSelectGenre: @escaping (Genre) -> Void
    ) -> UIViewController {
        let worker = SearchWorker(genreRepository: genreRepository)
        let callbackWorker = SearchCallbackWorker(genreRepository: callbackGenreRepository)
        let presenter = SearchPresenter()
        let interactor = SearchInteractor(presenter: presenter, worker: worker, callbackWorker: callbackWorker)
        let router = SearchRouter(onSelectGenre: onSelectGenre)
        let viewController = SearchViewController(interactor: interactor, router: router)
        presenter.viewController = viewController
        return viewController
    }
}
