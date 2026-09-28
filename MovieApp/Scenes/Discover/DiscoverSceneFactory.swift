import UIKit

enum DiscoverSceneFactory {
    static func make(genreRepository: any GenreRepository) -> UIViewController {
        let worker = DiscoverWorker(genreRepository: genreRepository)
        let presenter = DiscoverPresenter()
        let interactor = DiscoverInteractor(presenter: presenter, worker: worker)
        let viewController = DiscoverViewController(interactor: interactor)
        presenter.viewController = viewController
        return viewController
    }
}
