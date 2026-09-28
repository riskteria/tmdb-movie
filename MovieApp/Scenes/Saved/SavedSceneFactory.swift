import UIKit

enum SavedSceneFactory {
    static func make(
        savedMoviesRepository: any SavedMoviesRepository,
        imageURLProvider: any ImageURLProviding,
        imageLoader: any ImageLoading,
        onSelectMovie: @escaping (Movie) -> Void
    ) -> UIViewController {
        let presenter = SavedPresenter(imageURLProvider: imageURLProvider)
        let worker = SavedWorker(savedMoviesRepository: savedMoviesRepository)
        let interactor = SavedInteractor(presenter: presenter, worker: worker)
        let router = SavedRouter(onSelectMovie: onSelectMovie)
        let viewController = SavedViewController(interactor: interactor, router: router, imageLoader: imageLoader)
        presenter.viewController = viewController
        return viewController
    }
}
