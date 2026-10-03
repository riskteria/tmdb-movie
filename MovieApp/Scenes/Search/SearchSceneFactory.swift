import UIKit

enum SearchSceneFactory {
    static func make(genreRepository: any IGenreRepository) -> UIViewController {
        let worker = SearchWorker(genreRepository: genreRepository)
        let presenter = SearchPresenter()
        let interactor = SearchInteractor(presenter: presenter, worker: worker)
        let viewController = SearchViewController(interactor: interactor)
        presenter.viewController = viewController
        return viewController
    }
}
