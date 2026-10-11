@testable import MovieApp
@testable import Networking
import Testing

struct MovieRepositoryTests {
    private let expectedMovie = Movie.fixture(posterPath: ImagePath(rawValue: "/poster.jpg"))

    @Test(arguments: [(TrendingWindow.day, TrendingMoviesDTO.TimeWindow.day), (.week, .week)])
    func trendingMapsTheMoviesForTheWindow(
        window: TrendingWindow,
        timeWindow: TrendingMoviesDTO.TimeWindow
    ) async throws {
        // Given
        let apiService = APIServiceStub(
            endpoint: .trendingMovies(timeWindow: timeWindow, parameters: .init(language: "en-US")),
            result: .success(try JSONFixture.named(.moviePage))
        )
        let sut: any IMovieRepository = MovieRepository(apiService: apiService)

        // When
        let movies = try await sut.trending(window: window)

        // Assert
        #expect(movies == [expectedMovie])
    }

    @Test(arguments: [(MovieCategory.nowPlaying, MovieListDTO.Category.nowPlaying), (.upcoming, .upcoming)])
    func moviesInRegionalCategorySendsTheRegion(category: MovieCategory, list: MovieListDTO.Category) async throws {
        // Given
        let apiService = APIServiceStub(
            endpoint: .movieList(category: list, parameters: .init(language: "en-US", page: 2, region: "US")),
            result: .success(try JSONFixture.named(.moviePage))
        )
        let sut: any IMovieRepository = MovieRepository(apiService: apiService)

        // When
        let page = try await sut.movies(in: category, page: 2)

        // Assert
        #expect(page.items == [expectedMovie])
    }

    @Test(arguments: [(MovieCategory.popular, MovieListDTO.Category.popular), (.topRated, .topRated)])
    func moviesInGlobalCategoryOmitsTheRegion(category: MovieCategory, list: MovieListDTO.Category) async throws {
        // Given
        let apiService = APIServiceStub(
            endpoint: .movieList(category: list, parameters: .init(language: "en-US", page: 2)),
            result: .success(try JSONFixture.named(.moviePage))
        )
        let sut: any IMovieRepository = MovieRepository(apiService: apiService)

        // When
        let page = try await sut.movies(in: category, page: 2)

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
    func discoverJoinsSeveralGenresWithCommas() async throws {
        // Given
        let parameters = DiscoverMoviesDTO.Parameters(
            language: "en-US",
            page: 1,
            sortBy: .popularityDescending,
            withGenres: "28,12"
        )
        let apiService = APIServiceStub(
            endpoint: .discoverMovies(parameters: parameters),
            result: .success(try JSONFixture.named(.moviePage))
        )
        let sut: any IMovieRepository = MovieRepository(apiService: apiService)

        // When
        let page = try await sut.discover(genreIDs: [28, 12], page: 1)

        // Assert
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
    func failedRequestThrowsTheNetworkErrorUnchanged() async {
        // Given
        let apiService = APIServiceStub(
            endpoint: .searchMovies(parameters: .init(query: "dune", language: "en-US", page: 1)),
            result: .failure(NetworkError.invalidResponse(statusCode: 401))
        )
        let sut: any IMovieRepository = MovieRepository(apiService: apiService)

        // When & Assert
        await #expect(throws: NetworkError.invalidResponse(statusCode: 401)) {
            try await sut.search(query: "dune", page: 1)
        }
    }
}
