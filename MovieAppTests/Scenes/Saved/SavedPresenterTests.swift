import Foundation
@testable import MovieApp
import Testing

@MainActor
struct SavedPresenterTests {
    private let viewController = SavedViewControllerSpy()
    private let sut: any ISavedPresenter

    init() {
        let presenter = SavedPresenter(imageURLProvider: ImageURLProviderStub())
        presenter.viewController = viewController
        sut = presenter
    }

    @Test
    func presentSavedMoviesShowsCountAndRows() throws {
        // Given
        let movies = [
            SavedMovie(movie: .fixture(id: 1, title: "Dune: Part Two", voteAverage: 8.2), savedAt: .now),
            SavedMovie(movie: .fixture(id: 2, title: "Undated", releaseDate: nil, voteAverage: 0), savedAt: .now)
        ]

        // When
        sut.presentSavedMovies(response: SavedModel.ObserveSavedMovies.Response(savedMovies: movies, capacity: 50))

        // Assert
        let content = try #require(viewController.displayedViewData.last?.content)
        let rows = content.movies
        #expect(content.header == "2 of 50 · the oldest is removed when full")
        #expect(rows.map(\.movie) == movies.map(\.movie))
        #expect(rows.map(\.title) == ["Dune: Part Two", "Undated"])
        #expect(rows.map(\.metadata) == ["2024", "-"])
        #expect(rows.map(\.rating) == ["8.2", nil])
    }

    @Test
    func presentSavedMoviesShowsEmptyState() {
        // When
        sut.presentSavedMovies(response: SavedModel.ObserveSavedMovies.Response(savedMovies: [], capacity: 50))

        // Assert
        let expected = SavedModel.ObserveSavedMovies.ViewData.empty(
            title: "Save movies to watch later",
            message: "Tap Save on any movie. Up to 50 stay on this device, even offline."
        )
        #expect(viewController.displayedViewData == [expected])
    }
}

@MainActor
private extension SavedModel.ObserveSavedMovies.ViewData {
    var content: (header: String, movies: [SavedModel.DisplayedMovie])? {
        if case let .content(header, movies) = self { (header, movies) } else { nil }
    }
}

@MainActor
private final class SavedViewControllerSpy: ISavedViewController {
    private(set) var displayedViewData: [SavedModel.ObserveSavedMovies.ViewData] = []

    func displaySavedMovies(viewData: SavedModel.ObserveSavedMovies.ViewData) {
        displayedViewData.append(viewData)
    }
}
