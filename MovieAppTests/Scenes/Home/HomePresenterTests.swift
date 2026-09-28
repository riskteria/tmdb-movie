import Foundation
@testable import MovieApp
import Testing

@MainActor
struct HomePresenterTests {
    private let viewController = HomeViewControllerSpy()
    private let sut = HomePresenter(imageURLProvider: ImageURLProvidingStub())

    init() {
        sut.viewController = viewController
    }

    @Test
    func presentHomeShowsAtMostFiveBannersWithMetadata() throws {
        // Given
        let movies = (1...6).map { Movie.fixture(id: $0) }

        // When
        sut.presentHome(response: makeResponse(trending: .success(movies), genres: [.scienceFiction, .adventure]))

        // Assert
        let hero = try #require(viewController.sections.first)
        let banners = try #require(hero.items.first?.banners)
        #expect(hero.section == .hero)
        #expect(banners.map(\.movie) == Array(movies.prefix(5)))
        #expect(banners.first?.metadata == "2024 • Science Fiction, Adventure • Movie")
    }

    @Test
    func presentHomeHidesFailedAndEmptySections() {
        // When
        sut.presentHome(
            response: makeResponse(
                trending: .success([.fixture(id: 1)]),
                popular: .failure(StubError.failed),
                topRated: .success(.fixture([])),
                upcoming: .success(.fixture([.fixture(id: 2)]))
            )
        )

        // Assert
        #expect(viewController.sections.map(\.section) == [.hero, .upcoming])
        #expect(viewController.sections.last?.title == "Upcoming")
    }

    @Test
    func presentHomeFormatsContinueWatchingTimeLeft() throws {
        // Given
        let item = ContinueWatchingItem(
            progress: .fixture(contentID: 1, position: .seconds(95), duration: .seconds(153)),
            details: .fixture(movie: .fixture(id: 1, title: "Oppenheimer"))
        )

        // When
        sut.presentHome(response: makeResponse(continueWatching: .success([item])))

        // Assert
        let section = try #require(viewController.sections.first)
        let displayed = try #require(section.items.first?.continueWatching)
        #expect(section.title == "Continue Watching")
        #expect(displayed.movie == item.details.movie)
        #expect(displayed.title == "Oppenheimer")
        #expect(displayed.subtitle == "Trailer · 0:58 left")
        #expect(displayed.progress == item.progress.progress)
    }

    @Test
    func presentHomeUsesPosterURLsAndTitledPlaceholders() throws {
        // Given
        let movie = Movie.fixture(id: 1, title: "Wicked", posterPath: ImagePath(rawValue: "/wicked.jpg"))

        // When
        sut.presentHome(response: makeResponse(popular: .success(.fixture([movie]))))

        // Assert
        let poster = try #require(viewController.sections.first?.items.first?.poster)
        #expect(poster.movie == movie)
        #expect(poster.artwork.url?.absoluteString == "https://images.test/posterMedium/wicked.jpg")
        #expect(poster.artwork.placeholderTitle == "Wicked")
    }

    @Test
    func presentHomeShowsFailureWhenEverySectionFails() {
        // Given
        let failure = StubError.failed

        // When
        sut.presentHome(
            response: makeResponse(
                trending: .failure(failure),
                continueWatching: .failure(failure),
                popular: .failure(failure),
                topRated: .failure(failure),
                upcoming: .failure(failure)
            )
        )

        // Assert
        #expect(viewController.displayedViewData == [.failure(message: "Unable to load movies")])
    }

    @Test
    func presentHomeShowsEmptyStateWhenEverySectionIsEmpty() {
        // When
        sut.presentHome(response: makeResponse())

        // Assert
        #expect(viewController.displayedViewData == [.empty(message: "No movies to show yet")])
    }

    private func makeResponse(
        trending: Result<[Movie], any Error> = .success([]),
        continueWatching: Result<[ContinueWatchingItem], any Error> = .success([]),
        popular: Result<Page<Movie>, any Error> = .success(.fixture([])),
        topRated: Result<Page<Movie>, any Error> = .success(.fixture([])),
        upcoming: Result<Page<Movie>, any Error> = .success(.fixture([])),
        genres: [Genre] = []
    ) -> HomeModel.LoadHome.Response {
        HomeModel.LoadHome.Response(
            trending: trending,
            continueWatching: continueWatching,
            popular: popular,
            topRated: topRated,
            upcoming: upcoming,
            genres: .success(genres)
        )
    }
}

@MainActor
private final class HomeViewControllerSpy: IHomeViewController {
    private(set) var displayedViewData: [HomeModel.LoadHome.ViewData] = []

    var sections: [HomeModel.DisplayedSection] {
        guard case .content(let sections) = displayedViewData.last else { return [] }
        return sections
    }

    func displayHome(viewData: HomeModel.LoadHome.ViewData) {
        displayedViewData.append(viewData)
    }
}

private extension HomeModel.Item {
    var banners: [HomeModel.DisplayedBanner]? {
        if case .hero(let banners) = self { banners } else { nil }
    }

    var continueWatching: HomeModel.DisplayedContinueWatching? {
        if case .continueWatching(let item) = self { item } else { nil }
    }

    var poster: HomeModel.DisplayedPoster? {
        if case .poster(let poster, _) = self { poster } else { nil }
    }
}
