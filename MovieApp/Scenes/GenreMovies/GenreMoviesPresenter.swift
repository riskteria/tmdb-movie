import Foundation

protocol IGenreMoviesPresenter {
    func presentMovies(response: GenreMoviesModel.LoadNextPage.Response)
}

final class GenreMoviesPresenter {
    weak var viewController: (any IGenreMoviesViewController)?
    private let imageURLProvider: any ImageURLProviding

    init(imageURLProvider: any ImageURLProviding) {
        self.imageURLProvider = imageURLProvider
    }
}

// MARK: - IGenreMoviesPresenter
extension GenreMoviesPresenter: IGenreMoviesPresenter {
    func presentMovies(response: GenreMoviesModel.LoadNextPage.Response) {
        let movies = response.movies.map(makeDisplayedMovie(from:))
        viewController?.displayMovies(viewData: makeViewData(movies: movies, status: response.status))
    }
}

private extension GenreMoviesPresenter {
    func makeViewData(
        movies: [GenreMoviesModel.DisplayedMovie],
        status: GenreMoviesModel.LoadStatus
    ) -> GenreMoviesModel.LoadNextPage.ViewData {
        switch status {
        case .loading where movies.isEmpty:
            .loading
        case .failed where movies.isEmpty:
            .failure(message: String(localized: "Unable to load movies"))
        case .loaded where movies.isEmpty:
            .empty(message: String(localized: "No movies in this genre yet"))
        case .loading:
            .content(movies: movies, footer: .spinner)
        case .failed:
            .content(movies: movies, footer: .retry(message: String(localized: "Couldn’t load more movies")))
        case .loaded:
            .content(movies: movies, footer: .hidden)
        }
    }

    func makeDisplayedMovie(from movie: Movie) -> GenreMoviesModel.DisplayedMovie {
        GenreMoviesModel.DisplayedMovie(
            movie: movie,
            title: movie.title,
            artwork: DisplayedArtwork(
                path: movie.posterPath,
                size: .posterMedium,
                placeholderSeed: movie.id,
                placeholderTitle: movie.title,
                imageURLProvider: imageURLProvider
            ),
            rating: movie.voteAverage > 0 ? movie.voteAverage.formatted(.number.precision(.fractionLength(1))) : nil
        )
    }
}
