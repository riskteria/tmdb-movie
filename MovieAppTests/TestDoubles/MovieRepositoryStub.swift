@testable import MovieApp
import Synchronization

final class MovieRepositoryStub: MovieRepository {
    enum Call: Equatable, Sendable {
        case trending(TrendingWindow)
        case movies(MovieCategory, page: Int)
        case discover([Genre.ID], page: Int)
        case search(String, page: Int)
        case details(Movie.ID)
    }

    private let trendingMovies: [Movie]
    private let moviePage: Page<Movie>
    // A movie missing from this dictionary makes `details(movieID:)` throw.
    private let detailsByID: [Movie.ID: MovieDetails]
    private let recordedCalls = Mutex<[Call]>([])

    var calls: [Call] {
        recordedCalls.withLock { $0 }
    }

    init(
        trendingMovies: [Movie] = [],
        moviePage: Page<Movie> = Page(number: 1, items: [], totalPages: 1, totalResults: 0),
        detailsByID: [Movie.ID: MovieDetails] = [:]
    ) {
        self.trendingMovies = trendingMovies
        self.moviePage = moviePage
        self.detailsByID = detailsByID
    }

    func trending(window: TrendingWindow) async throws -> [Movie] {
        record(.trending(window))
        return trendingMovies
    }

    func movies(in category: MovieCategory, page: Int) async throws -> Page<Movie> {
        record(.movies(category, page: page))
        return moviePage
    }

    func discover(genreIDs: [Genre.ID], page: Int) async throws -> Page<Movie> {
        record(.discover(genreIDs, page: page))
        return moviePage
    }

    func search(query: String, page: Int) async throws -> Page<Movie> {
        record(.search(query, page: page))
        return moviePage
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
