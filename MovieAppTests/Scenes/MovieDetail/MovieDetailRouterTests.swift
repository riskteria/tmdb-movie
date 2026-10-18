@testable import MovieApp
import Testing

@MainActor
struct MovieDetailRouterTests {
    private let movie = Movie.fixture()

    @Test
    func routeToMovieDetailCallsOnSelectMovie() {
        // Given
        var selectedMovies: [Movie] = []
        let sut: any IMovieDetailRouter = MovieDetailRouter(
            onSelectMovie: { movie in selectedMovies.append(movie) },
            onWatchTrailer: { _ in },
            onShare: { _ in }
        )

        // When
        sut.routeToMovieDetail(movie: movie)

        // Assert
        #expect(selectedMovies == [movie])
    }

    @Test
    func routeToTrailerCallsOnWatchTrailer() {
        // Given
        let trailer = Video.fixture()
        var watchedTrailers: [Video] = []
        let sut: any IMovieDetailRouter = MovieDetailRouter(
            onSelectMovie: { _ in },
            onWatchTrailer: { video in watchedTrailers.append(video) },
            onShare: { _ in }
        )

        // When
        sut.routeToTrailer(video: trailer)

        // Assert
        #expect(watchedTrailers == [trailer])
    }

    @Test
    func routeToShareCallsOnShare() {
        // Given
        var sharedMovies: [Movie] = []
        let sut: any IMovieDetailRouter = MovieDetailRouter(
            onSelectMovie: { _ in },
            onWatchTrailer: { _ in },
            onShare: { movie in sharedMovies.append(movie) }
        )

        // When
        sut.routeToShare(movie: movie)

        // Assert
        #expect(sharedMovies == [movie])
    }
}
