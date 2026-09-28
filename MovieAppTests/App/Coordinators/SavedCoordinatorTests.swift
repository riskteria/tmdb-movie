@testable import MovieApp
import Testing
import UIKit

@MainActor
struct SavedCoordinatorTests {
    private let scenes = SceneFactorySpy()
    private let sut: SavedCoordinator

    init() {
        sut = SavedCoordinator(dependencies: scenes)
    }

    @Test
    func startShowsSavedAsRoot() {
        // When
        sut.start()

        // Assert
        #expect(sut.navigationController.viewControllers == [scenes.saved])
    }

    @Test
    func selectingSavedMovieShowsItsDetail() throws {
        // Given
        let movie = Movie.fixture()
        sut.start()

        // When
        let selectMovie = try #require(scenes.savedSelectionHandler)
        selectMovie(movie)

        // Assert
        #expect(scenes.movieDetailRequests == [movie])
    }
}
