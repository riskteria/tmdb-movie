import Foundation
@testable import MovieApp
import Testing

@MainActor
struct GenreMoviesPresenterTests {
    private let viewController = GenreMoviesViewControllerSpy()
    private let sut = GenreMoviesPresenter(imageURLProvider: ImageURLProvidingStub())

    init() {
        sut.viewController = viewController
    }

    @Test
    func loadedMoviesShowAsPostersWithoutFooter() {
        // Given
        let movie = Movie.fixture(posterPath: ImagePath(rawValue: "/dune.jpg"))

        // When
        sut.presentMovies(response: .init(movies: [movie], status: .loaded))

        // Assert
        let expectedMovie = GenreMoviesModel.DisplayedMovie(
            movie: movie,
            title: "Dune: Part Two",
            artwork: DisplayedArtwork(
                url: URL(string: "https://images.test/posterMedium/dune.jpg"),
                placeholderSeed: 693134,
                placeholderTitle: "Dune: Part Two"
            ),
            rating: "8.2"
        )
        #expect(viewController.displayedViewData == [.content(movies: [expectedMovie], footer: .hidden)])
    }

    @Test
    func failedFirstPageShowsFullScreenFailure() {
        // When
        sut.presentMovies(response: .init(movies: [], status: .failed))

        // Assert
        #expect(viewController.displayedViewData == [.failure(message: "Unable to load movies")])
    }
}

@MainActor
private final class GenreMoviesViewControllerSpy: IGenreMoviesViewController {
    private(set) var displayedViewData: [GenreMoviesModel.LoadNextPage.ViewData] = []

    func displayMovies(viewData: GenreMoviesModel.LoadNextPage.ViewData) {
        displayedViewData.append(viewData)
    }
}
