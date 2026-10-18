@testable import MovieApp
import Testing
import UIKit

@MainActor
struct MovieDetailFlowTests {
    private let scenes = SceneFactorySpy()
    private let navigationController = UINavigationController(rootViewController: UIViewController())
    private let dune = Movie.fixture()
    private let sut: any MovieDetailNavigator

    init() {
        sut = MovieDetailFlow(navigationController: navigationController, dependencies: scenes)
    }

    @Test
    func selectingARecommendationShowsThatMoviesDetail() throws {
        // Given
        let interstellar = Movie.fixture(id: 157336, title: "Interstellar")
        sut.showDetail(for: dune, transition: .push)

        // When
        let selectMovie = try #require(scenes.movieDetailSelectionHandler)
        selectMovie(interstellar)

        // Assert
        #expect(scenes.movieDetailRequests == [dune, interstellar])
        #expect(navigationController.viewControllers.count == 3)
    }

    @Test
    func watchingATrailerAsksForThatTrailer() throws {
        // Given
        let trailer = Video.fixture()
        sut.showDetail(for: dune, transition: .push)

        // When
        let watchTrailer = try #require(scenes.movieDetailTrailerHandler)
        watchTrailer(trailer)

        // Assert
        #expect(scenes.trailerRequests == [trailer])
    }

    @Test
    func sharingAsksForThatMoviesShareSheet() throws {
        // Given
        sut.showDetail(for: dune, transition: .push)

        // When
        let share = try #require(scenes.movieDetailShareHandler)
        share(dune)

        // Assert
        #expect(scenes.shareRequests == [dune])
    }
}
