import UIKit

enum SearchSceneFactory {
    static func make(
        genreRepository: any IGenreRepository,
        onSelectGenre: @escaping (Genre) -> Void
    ) -> UIViewController {
        let worker = SearchWorker(genreRepository: genreRepository)
        let presenter = SearchPresenter()
        let interactor = SearchInteractor(presenter: presenter, worker: worker)
        let router = SearchRouter(onSelectGenre: onSelectGenre)
        let viewController = SearchViewController(interactor: interactor, router: router)
        presenter.viewController = viewController
        return viewController
    }
}
