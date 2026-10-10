@testable import MovieApp
import Testing

struct MovieRepositoryTests {
    private let expectedMovie = Movie.fixture(posterPath: ImagePath(rawValue: "/poster.jpg"))

    @Test
    func trendingMapsTheMoviesForTheWindow() async throws {
        // Given
        let apiService = APIServiceStub(
            endpoint: .trendingMovies(timeWindow: .week, parameters: .init(language: "en-US")),
            result: .success(try JSONFixture.named(.moviePage))
        )
        let sut: any IMovieRepository = MovieRepository(apiService: apiService)

        // When
        let movies = try await sut.trending(window: .week)

        // Assert
        #expect(movies == [expectedMovie])
    }

    @Test
    func moviesInRegionalCategorySendsTheRegion() async throws {
        // Given
        let apiService = APIServiceStub(
            endpoint: .movieList(category: .upcoming, parameters: .init(language: "en-US", page: 2, region: "US")),
            result: .success(try JSONFixture.named(.moviePage))
        )
        let sut: any IMovieRepository = MovieRepository(apiService: apiService)

        // When
        let page = try await sut.movies(in: .upcoming, page: 2)

        // Assert
        #expect(page.items == [expectedMovie])
    }

    @Test
    func moviesInGlobalCategoryOmitsTheRegion() async throws {
        // Given
        let apiService = APIServiceStub(
            endpoint: .movieList(category: .popular, parameters: .init(language: "en-US", page: 2)),
            result: .success(try JSONFixture.named(.moviePage))
        )
        let sut: any IMovieRepository = MovieRepository(apiService: apiService)

        // When
        let page = try await sut.movies(in: .popular, page: 2)

        // Assert
        #expect(page.items == [expectedMovie])
    }

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
        let sut: any IMovieRepository = MovieRepository(apiService: apiService)

        // When
        let page = try await sut.discover(genreIDs: [28], page: 2)

        // Assert
        #expect(page.number == 2)
        #expect(page.hasNextPage)
        #expect(page.items == [expectedMovie])
    }

    @Test
    func searchMapsThePageOfMovies() async throws {
        // Given
        let apiService = APIServiceStub(
            endpoint: .searchMovies(parameters: .init(query: "dune", language: "en-US", page: 2)),
            result: .success(try JSONFixture.named(.moviePage))
        )
        let sut: any IMovieRepository = MovieRepository(apiService: apiService)

        // When
        let page = try await sut.search(query: "dune", page: 2)

        // Assert
        #expect(page.items == [expectedMovie])
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
        let sut: any IMovieRepository = MovieRepository(apiService: apiService)

        // When
        let details = try await sut.details(movieID: 693134)

        // Assert
        #expect(details.certification == "PG-13")
        #expect(details.runtime == .seconds(167 * 60))
    }
}
