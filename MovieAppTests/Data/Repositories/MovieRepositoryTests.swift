@testable import MovieApp
import Testing

struct MovieRepositoryTests {
    @Test
    func discoverMapsThePageOfMovies() async throws {
        // Given
        let parameters = DiscoverMoviesDTO.Parameters(
            language: "en-US",
            page: 2,
            sortBy: .popularityDescending,
            withGenres: "28"
        )
        let apiService = APIServiceStub(
            endpoint: .discoverMovies(parameters: parameters),
            result: .success(try JSONFixture.named(.moviePage))
        )
        let sut = MovieRepository(apiService: apiService)

        // When
        let page = try await sut.discover(genreIDs: [28], page: 2)

        // Assert
        #expect(page.number == 2)
        #expect(page.hasNextPage)
        #expect(page.items == [.fixture(posterPath: ImagePath(rawValue: "/poster.jpg"))])
    }

    @Test
    func detailsPrefersTheUSTheatricalCertification() async throws {
        // Given
        let parameters = MovieDetailsDTO.Parameters(
            appendToResponse: [.credits, .videos, .releaseDates, .recommendations],
            language: "en-US"
        )
        let apiService = APIServiceStub(
            endpoint: .movieDetails(movieID: 693134, parameters: parameters),
            result: .success(try JSONFixture.named(.movieDetails))
        )
        let sut = MovieRepository(apiService: apiService)

        // When
        let details = try await sut.details(movieID: 693134)

        // Assert
        #expect(details.certification == "PG-13")
        #expect(details.runtime == .seconds(167 * 60))
    }
}
