@testable import MovieApp
import Synchronization

final class MovieRepositoryStub: IMovieRepository {
    enum Call: Equatable, Sendable {
        case trending(TrendingWindow)
        case movies(MovieCategory, page: Int)
        case discover([Genre.ID], page: Int)
        case search(String, page: Int)
        case details(Movie.ID)
    }

    private let trendingResult: Result<[Movie], any Error>
    private let moviesResult: Result<Page<Movie>, any Error>
    private let discoverResult: Result<Page<Movie>, any Error>
    private let searchResult: Result<Page<Movie>, any Error>

    private let detailsByID: [Movie.ID: MovieDetails]
    private let recordedCalls = Mutex<[Call]>([])

    var calls: [Call] {
        recordedCalls.withLock { $0 }
    }

    init(
        trending: Result<[Movie], any Error> = .success([]),
        movies: Result<Page<Movie>, any Error> = .success(.fixture([])),
        discover: Result<Page<Movie>, any Error> = .success(.fixture([])),
        search: Result<Page<Movie>, any Error> = .success(.fixture([])),
        detailsByID: [Movie.ID: MovieDetails] = [:]
    ) {
        trendingResult = trending
        moviesResult = movies
        discoverResult = discover
        searchResult = search
        self.detailsByID = detailsByID
    }

    func trending(window: TrendingWindow) async throws -> [Movie] {
        record(.trending(window))
        return try trendingResult.get()
    }

    func movies(in category: MovieCategory, page: Int) async throws -> Page<Movie> {
        record(.movies(category, page: page))
        return try moviesResult.get()
    }

    func discover(genreIDs: [Genre.ID], page: Int) async throws -> Page<Movie> {
        record(.discover(genreIDs, page: page))
        return try discoverResult.get()
    }

    func search(query: String, page: Int) async throws -> Page<Movie> {
        record(.search(query, page: page))
        return try searchResult.get()
    }

    func details(movieID: Movie.ID) async throws -> MovieDetails {
        record(.details(movieID))
        guard let details = detailsByID[movieID] else { throw StubError.failed }
        return details
    }

    private func record(_ call: Call) {
        recordedCalls.withLock { $0.append(call) }
    }
}
