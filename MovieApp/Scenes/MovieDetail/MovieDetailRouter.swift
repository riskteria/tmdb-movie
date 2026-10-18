protocol IMovieDetailRouter {
    func routeToMovieDetail(movie: Movie)
    func routeToTrailer(video: Video)
    func routeToShare(movie: Movie)
}

final class MovieDetailRouter {
    private let onSelectMovie: (Movie) -> Void
    private let onWatchTrailer: (Video) -> Void
    private let onShare: (Movie) -> Void

    init(
        onSelectMovie: @escaping (Movie) -> Void,
        onWatchTrailer: @escaping (Video) -> Void,
        onShare: @escaping (Movie) -> Void
    ) {
        self.onSelectMovie = onSelectMovie
        self.onWatchTrailer = onWatchTrailer
        self.onShare = onShare
    }
}

// MARK: - IMovieDetailRouter
extension MovieDetailRouter: IMovieDetailRouter {
    func routeToMovieDetail(movie: Movie) {
        onSelectMovie(movie)
    }

    func routeToTrailer(video: Video) {
        onWatchTrailer(video)
    }

    func routeToShare(movie: Movie) {
        onShare(movie)
    }
}
