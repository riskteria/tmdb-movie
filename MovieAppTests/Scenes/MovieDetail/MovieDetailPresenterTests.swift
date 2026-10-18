import Foundation
@testable import MovieApp
import Testing

@MainActor
struct MovieDetailPresenterTests {
    private let viewController = MovieDetailViewControllerSpy()
    private let sut: any IMovieDetailPresenter
    private let movie = Movie.fixture(backdropPath: ImagePath(rawValue: "/dune.jpg"))

    init() {
        let presenter = MovieDetailPresenter(
            imageURLProvider: ImageURLProviderStub(),
            videoURLProvider: VideoURLProviderStub()
        )
        presenter.viewController = viewController
        sut = presenter
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
        sut.presentDetails(response: makeResponse(details))

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
        sut.presentDetails(response: makeResponse(details))

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

    @Test
    func presentDetailsKeepsTheMovieForSharing() throws {
        // Given
        let details = MovieDetails.fixture(movie: movie)

        // When
        sut.presentDetails(response: makeResponse(details))

        // Assert
        let detail = try #require(viewController.displayedViewData.last?.contentDetail)
        #expect(detail.movie == movie)
    }

    @Test
    func presentDetailsWhileLoadingKeepsWatchPending() throws {
        // When
        sut.presentDetails(response: MovieDetailModel.LoadDetails.Response(movie: movie, details: nil))

        // Assert
        let detail = try #require(viewController.displayedViewData.last?.loadingDetail)
        #expect(detail.watch == .pending)
    }

    @Test
    func presentDetailsOffersWatchWithTheMainTrailer() throws {
        // Given
        let officialTrailer = Video.fixture(key: "official-trailer")
        let details = MovieDetails.fixture(
            movie: movie,
            videos: [.fixture(key: "teaser", kind: .teaser), officialTrailer]
        )

        // When
        sut.presentDetails(response: makeResponse(details))

        // Assert
        let detail = try #require(viewController.displayedViewData.last?.contentDetail)
        #expect(detail.watch == .available(officialTrailer))
    }

    @Test
    func presentDetailsHidesWatchWithoutVideos() throws {
        // Given
        let details = MovieDetails.fixture(movie: movie, videos: [])

        // When
        sut.presentDetails(response: makeResponse(details))

        // Assert
        let detail = try #require(viewController.displayedViewData.last?.contentDetail)
        #expect(detail.watch == .unavailable)
    }

    @Test
    func presentDetailsShowsTheScoreAndShortVoteCount() throws {
        // Given
        let details = MovieDetails.fixture(movie: .fixture(voteAverage: 8.24), voteCount: 6123)

        // When
        sut.presentDetails(response: makeResponse(details))

        // Assert
        let extras = try #require(viewController.displayedViewData.last?.contentExtras)
        let expectedRating = MovieDetailModel.DisplayedRating(
            score: "8.2",
            votes: "TMDB · 6.1K votes",
            accessibilityLabel: "Rated 8.2 out of 10, 6,123 votes"
        )
        #expect(extras.rating == expectedRating)
    }

    @Test
    func presentDetailsUsesTheSingularForOneVote() throws {
        // Given
        let details = MovieDetails.fixture(movie: movie, voteCount: 1)

        // When
        sut.presentDetails(response: makeResponse(details))

        // Assert
        let extras = try #require(viewController.displayedViewData.last?.contentExtras)
        #expect(extras.rating?.votes == "TMDB · 1 vote")
    }

    @Test
    func presentDetailsHidesTheRatingWithoutVotes() throws {
        // Given
        let details = MovieDetails.fixture(movie: movie, voteCount: 0)

        // When
        sut.presentDetails(response: makeResponse(details))

        // Assert
        let extras = try #require(viewController.displayedViewData.last?.contentExtras)
        #expect(extras.rating == nil)
    }

    @Test
    func presentDetailsListsTheCastWithProfileArtwork() throws {
        // Given
        let member = CastMember.fixture(profilePath: ImagePath(rawValue: "/chalamet.jpg"))
        let details = MovieDetails.fixture(movie: movie, cast: [member])

        // When
        sut.presentDetails(response: makeResponse(details))

        // Assert
        let extras = try #require(viewController.displayedViewData.last?.contentExtras)
        let expectedMember = MovieDetailModel.DisplayedCastMember(
            id: member.id,
            name: "Timothée Chalamet",
            character: "Paul Atreides",
            artwork: DisplayedArtwork(
                url: URL(string: "https://images.test/profile/chalamet.jpg"),
                placeholderSeed: member.id,
                placeholderTitle: "TC"
            )
        )
        #expect(extras.cast == [expectedMember])
    }

    @Test(
        arguments: [
            ("Timothée Chalamet", "TC"),
            ("Zendaya", "Z"),
            ("Rebecca Louisa Ferguson", "RF"),
            (" Josh  Brolin ", "JB")
        ]
    )
    func presentDetailsMakesInitials(name: String, initials: String) throws {
        // Given
        let details = MovieDetails.fixture(movie: movie, cast: [.fixture(name: name)])

        // When
        sut.presentDetails(response: makeResponse(details))

        // Assert
        let extras = try #require(viewController.displayedViewData.last?.contentExtras)
        #expect(extras.cast.first?.artwork.placeholderTitle == initials)
    }

    @Test
    func presentDetailsDropsDuplicateCastCredits() throws {
        // Given
        let details = MovieDetails.fixture(movie: movie, cast: [.fixture(), .fixture()])

        // When
        sut.presentDetails(response: makeResponse(details))

        // Assert
        let extras = try #require(viewController.displayedViewData.last?.contentExtras)
        #expect(extras.cast.count == 1)
    }

    @Test
    func presentDetailsShowsRecommendationsWithRatings() throws {
        // Given
        let recommendation = Movie.fixture(
            id: 157336,
            title: "Interstellar",
            posterPath: ImagePath(rawValue: "/interstellar.jpg"),
            voteAverage: 8.43
        )
        let details = MovieDetails.fixture(movie: movie, recommendations: [recommendation])

        // When
        sut.presentDetails(response: makeResponse(details))

        // Assert
        let extras = try #require(viewController.displayedViewData.last?.contentExtras)
        let expectedMovie = MovieDetailModel.DisplayedMovie(
            movie: recommendation,
            title: "Interstellar",
            rating: "8.4",
            artwork: DisplayedArtwork(
                url: URL(string: "https://images.test/posterMedium/interstellar.jpg"),
                placeholderSeed: 157336,
                placeholderTitle: "Interstellar"
            )
        )
        #expect(extras.moreLikeThis == .items([expectedMovie]))
    }

    @Test
    func presentDetailsHidesTheRatingOfAnUnratedRecommendation() throws {
        // Given
        let details = MovieDetails.fixture(movie: movie, recommendations: [.fixture(id: 1, voteAverage: 0)])

        // When
        sut.presentDetails(response: makeResponse(details))

        // Assert
        let extras = try #require(viewController.displayedViewData.last?.contentExtras)
        #expect(extras.moreLikeThis.items.map(\.rating) == [nil])
    }

    @Test
    func presentDetailsDropsDuplicateRecommendations() throws {
        // Given
        let details = MovieDetails.fixture(
            movie: movie,
            recommendations: [.fixture(id: 1), .fixture(id: 2), .fixture(id: 1)]
        )

        // When
        sut.presentDetails(response: makeResponse(details))

        // Assert
        let extras = try #require(viewController.displayedViewData.last?.contentExtras)
        #expect(extras.moreLikeThis.items.map(\.id) == [1, 2])
    }

    @Test
    func presentDetailsShowsAnEmptyMessageWithoutRecommendations() throws {
        // Given
        let details = MovieDetails.fixture(movie: movie, recommendations: [])

        // When
        sut.presentDetails(response: makeResponse(details))

        // Assert
        let extras = try #require(viewController.displayedViewData.last?.contentExtras)
        #expect(extras.moreLikeThis == .empty(message: "No similar movies yet"))
    }

    @Test
    func presentDetailsListsOnlyTrailersAndTeasersNewestFirst() throws {
        // Given
        let videos: [Video] = [
            .fixture(key: "teaser", kind: .teaser, publishedAt: .fixture(year: 2023, month: 4, day: 1)),
            .fixture(key: "trailer-1", kind: .trailer, publishedAt: .fixture(year: 2023, month: 5, day: 3)),
            .fixture(key: "featurette", kind: .featurette, publishedAt: .fixture(year: 2023, month: 6, day: 1)),
            .fixture(key: "trailer-2", kind: .trailer, publishedAt: .fixture(year: 2023, month: 12, day: 21)),
            .fixture(key: "undated", kind: .trailer, publishedAt: nil)
        ]
        let details = MovieDetails.fixture(movie: movie, videos: videos)

        // When
        sut.presentDetails(response: makeResponse(details))

        // Assert
        let extras = try #require(viewController.displayedViewData.last?.contentExtras)
        #expect(extras.trailers.items.map(\.video.key) == ["trailer-2", "trailer-1", "teaser", "undated"])
    }

    @Test
    func presentDetailsDescribesATrailerByKindAndDate() throws {
        // Given
        let video = Video.fixture(
            key: "dune-3",
            name: "Official Trailer 3",
            kind: .trailer,
            publishedAt: .fixture(year: 2023, month: 12, day: 21)
        )
        let details = MovieDetails.fixture(movie: movie, videos: [video])

        // When
        sut.presentDetails(response: makeResponse(details))

        // Assert
        let extras = try #require(viewController.displayedViewData.last?.contentExtras)
        let expectedTrailer = MovieDetailModel.DisplayedTrailer(
            video: video,
            title: "Official Trailer 3",
            metadata: "Trailer • Dec 21, 2023",
            accessibilityValue: "Trailer, December 21, 2023",
            artwork: DisplayedArtwork(
                url: URL(string: "https://example.com/thumb/dune-3"),
                placeholderSeed: movie.id,
                placeholderTitle: nil
            )
        )
        #expect(extras.trailers == .items([expectedTrailer]))
    }

    @Test
    func presentDetailsShowsAnEmptyMessageWithoutTrailers() throws {
        // Given
        let details = MovieDetails.fixture(movie: movie, videos: [.fixture(kind: .clip)])

        // When
        sut.presentDetails(response: makeResponse(details))

        // Assert
        let extras = try #require(viewController.displayedViewData.last?.contentExtras)
        #expect(extras.trailers == .empty(message: "No trailers yet"))
    }

    private func makeResponse(_ details: MovieDetails) -> MovieDetailModel.LoadDetails.Response {
        MovieDetailModel.LoadDetails.Response(movie: movie, details: .success(details))
    }
}

@MainActor
private extension MovieDetailModel.LoadDetails.ViewData {
    var loadingDetail: MovieDetailModel.DisplayedDetail? {
        if case .loading(let detail) = self { detail } else { nil }
    }

    var contentDetail: MovieDetailModel.DisplayedDetail? {
        if case .content(let detail, _) = self { detail } else { nil }
    }

    var contentExtras: MovieDetailModel.DisplayedExtras? {
        if case .content(_, let extras) = self { extras } else { nil }
    }
}

private extension MovieDetailModel.DisplayedTabContent {
    var items: [Item] {
        if case .items(let items) = self { items } else { [] }
    }
}

@MainActor
private final class MovieDetailViewControllerSpy: IMovieDetailViewController {
    private(set) var displayedViewData: [MovieDetailModel.LoadDetails.ViewData] = []

    func displayDetails(viewData: MovieDetailModel.LoadDetails.ViewData) {
        displayedViewData.append(viewData)
    }
}
