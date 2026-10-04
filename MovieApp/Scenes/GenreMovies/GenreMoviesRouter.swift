protocol IGenreMoviesRouter {
    func routeToMovieDetail(movie: Movie)
}

final class GenreMoviesRouter {
    private let onSelectMovie: (Movie) -> Void

    init(onSelectMovie: @escaping (Movie) -> Void) {
        self.onSelectMovie = onSelectMovie
    }
}

// MARK: - IGenreMoviesRouter
extension GenreMoviesRouter: IGenreMoviesRouter {
    func routeToMovieDetail(movie: Movie) {
        onSelectMovie(movie)
    }
}
