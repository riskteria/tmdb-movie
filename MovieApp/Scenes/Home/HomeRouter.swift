protocol IHomeRouter {
    func routeToMovieDetail(movie: Movie)
}

final class HomeRouter {
    private let onSelectMovie: (Movie) -> Void

    init(onSelectMovie: @escaping (Movie) -> Void) {
        self.onSelectMovie = onSelectMovie
    }
}

// MARK: - IHomeRouter
extension HomeRouter: IHomeRouter {
    func routeToMovieDetail(movie: Movie) {
        onSelectMovie(movie)
    }
}
