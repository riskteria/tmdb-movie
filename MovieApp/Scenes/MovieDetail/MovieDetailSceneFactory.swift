import UIKit

enum MovieDetailSceneFactory {
    static func make(
        movie: Movie,
        movieRepository: any IMovieRepository,
        imageURLProvider: any ImageURLProvider,
        imageLoader: any IImageLoader
    ) -> UIViewController {
        let presenter = MovieDetailPresenter(imageURLProvider: imageURLProvider)
        let worker = MovieDetailWorker(movieRepository: movieRepository)
        let interactor = MovieDetailInteractor(movie: movie, presenter: presenter, worker: worker)
        let viewController = MovieDetailViewController(interactor: interactor, imageLoader: imageLoader)
        presenter.viewController = viewController
        return viewController
    }
}
