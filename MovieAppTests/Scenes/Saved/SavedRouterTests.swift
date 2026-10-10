@testable import MovieApp
import Testing

@MainActor
struct SavedRouterTests {
    @Test
    func routeToMovieDetailPassesMovieToCoordinator() {
        // Given
        let movie = Movie.fixture()
        var routedMovies: [Movie] = []
        let sut: any ISavedRouter = SavedRouter { routedMovies.append($0) }

        // When
        sut.routeToMovieDetail(movie: movie)

        // Assert
        #expect(routedMovies == [movie])
    }
}
