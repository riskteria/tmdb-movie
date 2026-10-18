import UIKit

enum MovieDetailSceneFactory {
    struct Dependencies {
        let movieRepository: any IMovieRepository
        let savedMoviesRepository: any ISavedMoviesRepository
        let watchProgressRepository: any IWatchProgressRepository
        let imageURLProvider: any ImageURLProvider
        let videoURLProvider: any VideoURLProvider
        let imageLoader: any IImageLoader
    }

    static func make(
        movie: Movie,
        dependencies: Dependencies,
        onSelectMovie: @escaping (Movie) -> Void,
        onWatchTrailer: @escaping (Video) -> Void,
        onShare: @escaping (Movie) -> Void
    ) -> UIViewController {
        let presenter = MovieDetailPresenter(
            imageURLProvider: dependencies.imageURLProvider,
            videoURLProvider: dependencies.videoURLProvider
        )
        let worker = MovieDetailWorker(
            movieRepository: dependencies.movieRepository,
            savedMoviesRepository: dependencies.savedMoviesRepository,
            watchProgressRepository: dependencies.watchProgressRepository
        )
        let interactor = MovieDetailInteractor(movie: movie, presenter: presenter, worker: worker)
        let router = MovieDetailRouter(onSelectMovie: onSelectMovie, onWatchTrailer: onWatchTrailer, onShare: onShare)
        let viewController = MovieDetailViewController(
            interactor: interactor,
            router: router,
            imageLoader: dependencies.imageLoader
        )
        presenter.viewController = viewController
        return viewController
    }
}
