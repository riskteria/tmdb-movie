import UIKit

enum HomeSceneFactory {
    struct Dependencies {
        let movieRepository: any IMovieRepository
        let genreRepository: any IGenreRepository
        let watchProgressRepository: any IWatchProgressRepository
        let savedMoviesRepository: any ISavedMoviesRepository
        let imageURLProvider: any ImageURLProvider
        let imageLoader: any IImageLoader
    }

    static func make(dependencies: Dependencies, onSelectMovie: @escaping (Movie) -> Void) -> UIViewController {
        let worker = HomeWorker(
            movieRepository: dependencies.movieRepository,
            genreRepository: dependencies.genreRepository,
            watchProgressRepository: dependencies.watchProgressRepository,
            savedMoviesRepository: dependencies.savedMoviesRepository
        )
        let presenter = HomePresenter(imageURLProvider: dependencies.imageURLProvider)
        let interactor = HomeInteractor(presenter: presenter, worker: worker)
        let router = HomeRouter(onSelectMovie: onSelectMovie)
        let viewController = HomeViewController(
            interactor: interactor,
            router: router,
            imageLoader: dependencies.imageLoader
        )
        presenter.viewController = viewController
        return viewController
    }
}
