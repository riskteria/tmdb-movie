import Foundation
@testable import MovieApp
import Testing

@MainActor
struct GenreMoviesPresenterTests {
    private let viewController = GenreMoviesViewControllerSpy()
    private let sut: any IGenreMoviesPresenter

    init() {
        let presenter = GenreMoviesPresenter(imageURLProvider: ImageURLProviderStub())
        presenter.viewController = viewController
        sut = presenter
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
    func loadingNextPageShowsSpinnerFooter() {
        // When
        sut.presentMovies(response: .init(movies: [.fixture()], status: .loading))

        // Assert
        #expect(viewController.displayedViewData.last?.footer == .spinner)
    }

    @Test
    func failedNextPageShowsRetryFooter() {
        // When
        sut.presentMovies(response: .init(movies: [.fixture()], status: .failed))

        // Assert
        #expect(viewController.displayedViewData.last?.footer == .retry(message: "Couldn’t load more movies"))
    }

    @Test
    func loadingFirstPageShowsFullScreenLoading() {
        // When
        sut.presentMovies(response: .init(movies: [], status: .loading))

        // Assert
        #expect(viewController.displayedViewData == [.loading])
    }

    @Test
    func failedFirstPageShowsFullScreenFailure() {
        // When
        sut.presentMovies(response: .init(movies: [], status: .failed))

        // Assert
        #expect(viewController.displayedViewData == [.failure(message: "Unable to load movies")])
    }

    @Test
    func loadedEmptyGenreShowsEmptyState() {
        // When
        sut.presentMovies(response: .init(movies: [], status: .loaded))

        // Assert
        #expect(viewController.displayedViewData == [.empty(message: "No movies in this genre yet")])
    }
}

@MainActor
private extension GenreMoviesModel.LoadNextPage.ViewData {
    var footer: GenreMoviesModel.LoadMoreFooter? {
        if case .content(_, let footer) = self { footer } else { nil }
    }
}

@MainActor
private final class GenreMoviesViewControllerSpy: IGenreMoviesViewController {
    private(set) var displayedViewData: [GenreMoviesModel.LoadNextPage.ViewData] = []

    func displayMovies(viewData: GenreMoviesModel.LoadNextPage.ViewData) {
        displayedViewData.append(viewData)
    }
}
