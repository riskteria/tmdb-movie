@testable import MovieApp
import Testing

@MainActor
struct SearchPresenterTests {
    private let viewController = SearchViewControllerSpy()
    private let sut = SearchPresenter()

    init() {
        sut.viewController = viewController
    }

    @Test
    func presentGenresShowsEveryGenreWithCount() {
        // When
        sut.presentGenres(response: SearchModel.LoadGenres.Response(result: .success([.scienceFiction, .drama])))

        // Assert
        let expected = SearchModel.DisplayedContent(
            sectionTitle: "Browse by Genre",
            count: "2",
            genres: [
                SearchModel.DisplayedGenre(id: 878, name: "Science Fiction"),
                SearchModel.DisplayedGenre(id: 18, name: "Drama")
            ]
        )
        #expect(viewController.displayedViewData == [.content(expected)])
    }

    @Test
    func presentGenresShowsEmptyState() {
        // When
        sut.presentGenres(response: SearchModel.LoadGenres.Response(result: .success([])))

        // Assert
        #expect(viewController.displayedViewData == [.empty(message: "No genres available")])
    }

    @Test
    func presentGenresShowsFailure() {
        // When
        sut.presentGenres(response: SearchModel.LoadGenres.Response(result: .failure(StubError.failed)))

        // Assert
        #expect(viewController.displayedViewData == [.failure(message: "Unable to load genres")])
    }
}

@MainActor
private final class SearchViewControllerSpy: ISearchViewController {
    private(set) var displayedViewData: [SearchModel.LoadGenres.ViewData] = []

    func displayGenres(viewData: SearchModel.LoadGenres.ViewData) {
        displayedViewData.append(viewData)
    }
}
