import Foundation
@testable import MovieApp
@testable import Networking
import Testing

struct MovieRepositoryDetailsTests {
    @Test
    func detailsPrefersTheTheatricalCertification() async throws {
        // Given
        let sut = try makeSUT()

        // When
        let details = try await sut.details(movieID: 693134)

        // Assert
        #expect(details.certification == "PG-13")
    }

    @Test
    func detailsUsesTheRepositorysRegionForTheCertification() async throws {
        // Given
        let sut = try makeSUT(region: "GB")

        // When
        let details = try await sut.details(movieID: 693134)

        // Assert
        #expect(details.certification == "12A")
    }

    @Test
    func detailsFallsBackToTheFirstRatedReleaseWhenTheTheatricalOneIsUnrated() async throws {
        // Given
        let sut = try makeSUT(region: "CA")

        // When
        let details = try await sut.details(movieID: 693134)

        // Assert
        #expect(details.certification == "14A")
    }

    @Test
    func detailsHasNoCertificationForARegionWithoutReleases() async throws {
        // Given
        let sut = try makeSUT(region: "FR")

        // When
        let details = try await sut.details(movieID: 693134)

        // Assert
        #expect(details.certification == nil)
    }

    @Test
    func detailsConvertsTheRuntimeFromMinutes() async throws {
        // Given
        let sut = try makeSUT()

        // When
        let details = try await sut.details(movieID: 693134)

        // Assert
        #expect(details.runtime == .seconds(167 * 60))
    }

    @Test
    func detailsMapsTheMovie() async throws {
        // Given
        let sut = try makeSUT()

        // When
        let details = try await sut.details(movieID: 693134)

        // Assert
        let expectedMovie = Movie.fixture(
            posterPath: ImagePath(rawValue: "/poster.jpg"),
            backdropPath: ImagePath(rawValue: "/backdrop.jpg"),
            genreIDs: [878]
        )
        #expect(details.movie == expectedMovie)
    }

    @Test
    func detailsMapsTheGenres() async throws {
        // Given
        let sut = try makeSUT()

        // When
        let details = try await sut.details(movieID: 693134)

        // Assert
        #expect(details.genres == [.scienceFiction])
    }

    @Test
    func detailsListsTheCastInBillingOrder() async throws {
        // Given
        let sut = try makeSUT()

        // When
        let details = try await sut.details(movieID: 693134)

        // Assert
        let expectedCast = [
            CastMember(
                id: 1190667,
                name: "Timothée Chalamet",
                character: "Paul Atreides",
                profilePath: ImagePath(rawValue: "/chalamet.jpg")
            ),
            CastMember(id: 1190668, name: "Zendaya", character: "Chani", profilePath: nil)
        ]
        #expect(details.cast == expectedCast)
    }

    @Test
    func detailsKeepsOnlyYouTubeVideos() async throws {
        // Given
        let sut = try makeSUT()

        // When
        let details = try await sut.details(movieID: 693134)

        // Assert
        #expect(details.videos.map(\.key) == ["trailer-key", "teaser-key", "bloopers-key"])
    }

    @Test
    func detailsMapsVideoTypesToKinds() async throws {
        // Given
        let sut = try makeSUT()

        // When
        let details = try await sut.details(movieID: 693134)

        // Assert
        #expect(details.videos.map(\.kind) == [.trailer, .teaser, .other])
    }

    @Test
    func detailsReadsTheVideoPublishDate() async throws {
        // Given
        let sut = try makeSUT()

        // When
        let details = try await sut.details(movieID: 693134)

        // Assert
        #expect(details.videos.first?.publishedAt == Date(timeIntervalSince1970: 1_683_119_095))
    }

    @Test
    func detailsMapsTheRecommendations() async throws {
        // Given
        let sut = try makeSUT()

        // When
        let details = try await sut.details(movieID: 693134)

        // Assert
        let expectedRecommendation = Movie(
            id: 438631,
            title: "Dune",
            overview: "Paul Atreides arrives on Arrakis.",
            releaseDate: nil,
            posterPath: ImagePath(rawValue: "/dune.jpg"),
            backdropPath: nil,
            genreIDs: [878],
            voteAverage: 7.8
        )
        #expect(details.recommendations == [expectedRecommendation])
    }

    private func makeSUT(region: String = "US") throws -> any IMovieRepository {
        let parameters = MovieDetailsDTO.Parameters(
            appendToResponse: [.credits, .videos, .releaseDates, .recommendations],
            language: "en-US"
        )
        let apiService = APIServiceStub(
            endpoint: .movieDetails(movieID: 693134, parameters: parameters),
            result: .success(try JSONFixture.named(.movieDetails))
        )
        return MovieRepository(apiService: apiService, region: region)
    }
}
