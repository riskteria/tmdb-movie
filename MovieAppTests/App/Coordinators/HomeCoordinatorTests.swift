@testable import MovieApp
import Testing
import UIKit

@MainActor
struct HomeCoordinatorTests {
    private let scenes = SceneFactorySpy()
    private let sut: HomeCoordinator

    init() {
        sut = HomeCoordinator(dependencies: scenes)
    }

    @Test
    func startShowsHomeAsRoot() {
        // When
        sut.start()

        // Assert
        #expect(sut.navigationController.viewControllers == [scenes.home])
    }

    @Test
    func selectingMovieOnHomeShowsItsDetail() throws {
        // Given
        let movie = Movie.fixture()
        sut.start()

        // When
        let selectMovie = try #require(scenes.homeSelectionHandler)
        selectMovie(movie)

        // Assert
        #expect(scenes.movieDetailRequests == [movie])
    }
}
