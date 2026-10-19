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
        sut.presentSavedMovies(response: makeResponse(savedMovies: movies))

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
        sut.presentSavedMovies(response: makeResponse(savedMovies: []))

        // Assert
        let expected = SavedModel.ObserveSavedMovies.ViewData.empty(
            title: "Save movies to watch later",
            message: "Tap Save on any movie. Up to 50 stay on this device, even offline."
        )
        #expect(viewController.displayedViewData == [expected])
    }

    @Test
    func removeFailureMessage() {
        // Given
        let response = SavedModel.RemoveMovie.Response(
            movie: .fixture(id: 7, title: "Wicked"),
            result: .failure(StubError.failed)
        )

        // When
        sut.presentRemoveMovie(response: response)

        // Assert
        #expect(viewController.displayedRemovals == [.failure(movieID: 7, message: "Couldn't remove “Wicked”")])
    }

    private func makeResponse(savedMovies: [SavedMovie]) -> SavedModel.ObserveSavedMovies.Response {
        SavedModel.ObserveSavedMovies.Response(savedMovies: savedMovies, capacity: 50)
    }
}

@MainActor
private struct DisplayedContent {
    let header: String
    let movies: [SavedModel.DisplayedMovie]
}

@MainActor
private extension SavedModel.ObserveSavedMovies.ViewData {
    var content: DisplayedContent? {
        guard case let .content(header, movies) = self else { return nil }
        return DisplayedContent(header: header, movies: movies)
    }
}

@MainActor
private final class SavedViewControllerSpy: ISavedViewController {
    private(set) var displayedViewData: [SavedModel.ObserveSavedMovies.ViewData] = []
    private(set) var displayedRemovals: [SavedModel.RemoveMovie.ViewData] = []

    func displaySavedMovies(viewData: SavedModel.ObserveSavedMovies.ViewData) {
        displayedViewData.append(viewData)
    }

    func displayRemoveMovie(viewData: SavedModel.RemoveMovie.ViewData) {
        displayedRemovals.append(viewData)
    }
}
