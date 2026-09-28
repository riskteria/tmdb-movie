protocol ISavedRouter {
    func routeToMovieDetail(movie: Movie)
}

final class SavedRouter {
    private let onSelectMovie: (Movie) -> Void

    init(onSelectMovie: @escaping (Movie) -> Void) {
        self.onSelectMovie = onSelectMovie
    }
}

// MARK: - ISavedRouter
extension SavedRouter: ISavedRouter {
    func routeToMovieDetail(movie: Movie) {
        onSelectMovie(movie)
    }
}
