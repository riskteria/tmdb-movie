@testable import MovieApp
@testable import Networking
import Testing

struct GenreRepositoryTests {
    private let endpoint = TMDBEndpoint.movieGenres(parameters: .init(language: "en-US"))

    @Test
    func movieGenresMapsEveryGenreInTMDBsOrder() async throws {
        // Given
        let apiService = APIServiceStub(
            endpoint: endpoint,
            result: .success(try JSONFixture.named(.movieGenres))
        )
        let sut: any IGenreRepository = GenreRepository(apiService: apiService)

        // When
        let genres = try await sut.movieGenres()

        // Assert
        let expectedGenres = [
            Genre(id: 28, name: "Action"),
            Genre(id: 12, name: "Adventure"),
            Genre(id: 16, name: "Animation"),
            Genre(id: 35, name: "Comedy"),
            Genre(id: 80, name: "Crime"),
            Genre(id: 99, name: "Documentary"),
            Genre(id: 18, name: "Drama"),
            Genre(id: 10751, name: "Family"),
            Genre(id: 14, name: "Fantasy"),
            Genre(id: 36, name: "History"),
            Genre(id: 27, name: "Horror"),
            Genre(id: 10402, name: "Music"),
            Genre(id: 9648, name: "Mystery"),
            Genre(id: 10749, name: "Romance"),
            Genre(id: 878, name: "Science Fiction"),
            Genre(id: 10770, name: "TV Movie"),
            Genre(id: 53, name: "Thriller"),
            Genre(id: 10752, name: "War"),
            Genre(id: 37, name: "Western")
        ]
        #expect(genres == expectedGenres)
    }

    @Test
    func movieGenresAsksInTheRepositorysLanguage() async throws {
        // Given
        let apiService = APIServiceStub(
            endpoint: .movieGenres(parameters: .init(language: "de-DE")),
            result: .success(#"{ "genres": [{ "id": 12, "name": "Abenteuer" }] }"#)
        )
        let sut: any IGenreRepository = GenreRepository(apiService: apiService, language: "de-DE")

        // When
        let genres = try await sut.movieGenres()

        // Assert
        #expect(genres == [Genre(id: 12, name: "Abenteuer")])
    }

    @Test
    func failedRequestThrowsTheNetworkErrorUnchanged() async {
        // Given
        let apiService = APIServiceStub(
            endpoint: endpoint,
            result: .failure(NetworkError.invalidResponse(statusCode: 401))
        )
        let sut: any IGenreRepository = GenreRepository(apiService: apiService)

        // When & Assert
        await #expect(throws: NetworkError.invalidResponse(statusCode: 401)) {
            try await sut.movieGenres()
        }
    }

    @Test
    func cancelledRequestStaysACancellationError() async {
        // Given
        let apiService = APIServiceStub(endpoint: endpoint, result: .failure(CancellationError()))
        let sut: any IGenreRepository = GenreRepository(apiService: apiService)

        // When & Assert
        await #expect(throws: CancellationError.self) {
            try await sut.movieGenres()
        }
    }
}
