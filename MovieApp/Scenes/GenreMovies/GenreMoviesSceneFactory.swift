import UIKit

enum GenreMoviesSceneFactory {
    static func make(
        genre: Genre,
        movieRepository: any IMovieRepository,
        imageURLProvider: any ImageURLProvider,
        imageLoader: any IImageLoader,
        onSelectMovie: @escaping (Movie) -> Void
    ) -> UIViewController {
        let worker = GenreMoviesWorker(movieRepository: movieRepository)
        let presenter = GenreMoviesPresenter(imageURLProvider: imageURLProvider)
        let interactor = GenreMoviesInteractor(genreID: genre.id, presenter: presenter, worker: worker)
        let router = GenreMoviesRouter(onSelectMovie: onSelectMovie)
        let viewController = GenreMoviesViewController(
            title: genre.name,
            interactor: interactor,
            router: router,
            imageLoader: imageLoader
        )
        presenter.viewController = viewController
        return viewController
    }
}
