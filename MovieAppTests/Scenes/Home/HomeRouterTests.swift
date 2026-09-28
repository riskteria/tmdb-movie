@testable import MovieApp
import Testing

@MainActor
struct HomeRouterTests {
    @Test
    func routeToMovieDetailPassesMovieToCoordinator() {
        // Given
        let movie = Movie.fixture()
        var routedMovies: [Movie] = []
        let sut = HomeRouter { routedMovies.append($0) }

        // When
        sut.routeToMovieDetail(movie: movie)

        // Assert
        #expect(routedMovies == [movie])
    }
}
