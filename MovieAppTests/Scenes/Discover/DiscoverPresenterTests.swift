@testable import MovieApp
import Testing

@MainActor
struct DiscoverPresenterTests {
    private let viewController = DiscoverViewControllerSpy()
    private let sut = DiscoverPresenter()

    init() {
        sut.viewController = viewController
    }

    @Test
    func presentGenresShowsEveryGenreWithCount() {
        // When
        sut.presentGenres(response: DiscoverModel.LoadGenres.Response(result: .success([.scienceFiction, .drama])))

        // Assert
        let expected = DiscoverModel.DisplayedContent(
            sectionTitle: "Browse by Genre",
            count: "2",
            genres: [
                DiscoverModel.DisplayedGenre(id: 878, name: "Science Fiction"),
                DiscoverModel.DisplayedGenre(id: 18, name: "Drama")
            ]
        )
        #expect(viewController.displayedViewData == [.content(expected)])
    }

    @Test
    func presentGenresShowsEmptyState() {
        // When
        sut.presentGenres(response: DiscoverModel.LoadGenres.Response(result: .success([])))

        // Assert
        #expect(viewController.displayedViewData == [.empty(message: "No genres available")])
    }

    @Test
    func presentGenresShowsFailure() {
        // When
        sut.presentGenres(response: DiscoverModel.LoadGenres.Response(result: .failure(StubError.failed)))

        // Assert
        #expect(viewController.displayedViewData == [.failure(message: "Unable to load genres")])
    }
}

@MainActor
private final class DiscoverViewControllerSpy: IDiscoverViewController {
    private(set) var displayedViewData: [DiscoverModel.LoadGenres.ViewData] = []

    func displayGenres(viewData: DiscoverModel.LoadGenres.ViewData) {
        displayedViewData.append(viewData)
    }
}
