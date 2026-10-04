@testable import MovieApp
import Testing
import UIKit

@MainActor
struct SearchCoordinatorTests {
    private let scenes = SceneFactorySpy()
    private let sut: SearchCoordinator

    init() {
        sut = SearchCoordinator(dependencies: scenes)
    }

    @Test
    func startShowsSearchAsRoot() {
        // When
        sut.start()

        // Assert
        #expect(sut.navigationController.viewControllers == [scenes.search])
    }

    @Test
    func selectingGenreOnSearchShowsItsMovies() throws {
        // Given
        sut.start()

        // When
        let selectGenre = try #require(scenes.searchSelectionHandler)
        selectGenre(.drama)

        // Assert
        #expect(scenes.genreMoviesRequests == [.drama])
        #expect(sut.navigationController.viewControllers == [scenes.search, scenes.genreMovies])
    }

    @Test
    func selectingMovieInGenreMoviesShowsItsDetail() throws {
        // Given
        let movie = Movie.fixture()
        sut.start()
        let selectGenre = try #require(scenes.searchSelectionHandler)
        selectGenre(.drama)

        // When
        let selectMovie = try #require(scenes.genreMoviesSelectionHandler)
        selectMovie(movie)

        // Assert
        #expect(scenes.movieDetailRequests == [movie])
    }
}
