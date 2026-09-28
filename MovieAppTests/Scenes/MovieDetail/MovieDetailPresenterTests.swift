import Foundation
@testable import MovieApp
import Testing

@MainActor
struct MovieDetailPresenterTests {
    private let viewController = MovieDetailViewControllerSpy()
    private let sut = MovieDetailPresenter(imageURLProvider: ImageURLProvidingStub())
    private let movie = Movie.fixture(backdropPath: ImagePath(rawValue: "/dune.jpg"))

    init() {
        sut.viewController = viewController
    }

    @Test
    func presentDetailsWhileLoadingShowsTitleAndYear() throws {
        // When
        sut.presentDetails(response: MovieDetailModel.LoadDetails.Response(movie: movie, details: nil))

        // Assert
        let detail = try #require(viewController.displayedViewData.last?.loadingDetail)
        #expect(detail.title == "Dune: Part Two")
        #expect(detail.metadata == "2024")
        #expect(detail.artwork.url?.absoluteString == "https://images.test/backdropLarge/dune.jpg")
    }

    @Test
    func presentDetailsShowsFullMetadataLine() throws {
        // Given
        let details = MovieDetails.fixture(movie: movie)

        // When
        sut.presentDetails(response: MovieDetailModel.LoadDetails.Response(movie: movie, details: .success(details)))

        // Assert
        let detail = try #require(viewController.displayedViewData.last?.contentDetail)
        #expect(detail.metadata == "2024 • Science Fiction, Adventure • 2h 46m • PG-13")
        #expect(detail.overview == movie.overview)
    }

    @Test
    func presentDetailsSkipsMissingParts() throws {
        // Given
        let details = MovieDetails.fixture(
            movie: .fixture(releaseDate: nil),
            runtime: nil,
            genres: [],
            certification: nil
        )

        // When
        sut.presentDetails(response: MovieDetailModel.LoadDetails.Response(movie: movie, details: .success(details)))

        // Assert
        let detail = try #require(viewController.displayedViewData.last?.contentDetail)
        #expect(detail.metadata.isEmpty)
    }

    @Test
    func presentDetailsShowsFailure() {
        // Given
        let response = MovieDetailModel.LoadDetails.Response(movie: movie, details: .failure(StubError.failed))

        // When
        sut.presentDetails(response: response)

        // Assert
        #expect(viewController.displayedViewData == [.failure(message: "Unable to load this movie")])
    }
}

@MainActor
private extension MovieDetailModel.LoadDetails.ViewData {
    var loadingDetail: MovieDetailModel.DisplayedDetail? {
        if case .loading(let detail) = self { detail } else { nil }
    }

    var contentDetail: MovieDetailModel.DisplayedDetail? {
        if case .content(let detail) = self { detail } else { nil }
    }
}

@MainActor
private final class MovieDetailViewControllerSpy: IMovieDetailViewController {
    private(set) var displayedViewData: [MovieDetailModel.LoadDetails.ViewData] = []

    func displayDetails(viewData: MovieDetailModel.LoadDetails.ViewData) {
        displayedViewData.append(viewData)
    }
}
