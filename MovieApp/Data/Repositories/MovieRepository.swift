import Foundation

nonisolated struct MovieRepository {}

// MARK: - IMovieRepository
nonisolated extension MovieRepository: IMovieRepository {
    enum Failure: Error {
        case movieNotFound(Movie.ID)
    }

    func trending(window: TrendingWindow) async throws -> [Movie] {
        MockResponseCatalog.trending
    }

    func movies(in category: MovieCategory, page: Int) async throws -> Page<Movie> {
        switch category {
        case .nowPlaying, .popular:
            Self.page(of: MockResponseCatalog.popular, number: page)
        case .topRated:
            Self.page(of: MockResponseCatalog.topRated, number: page)
        case .upcoming:
            Self.page(of: MockResponseCatalog.upcoming, number: page)
        }
    }

    func discover(genreIDs: [Genre.ID], page: Int) async throws -> Page<Movie> {
        let movies = MockResponseCatalog.allMovies.filter { movie in movie.genreIDs.contains { genreIDs.contains($0) } }
        return Self.page(of: movies, number: page)
    }

    func search(query: String, page: Int) async throws -> Page<Movie> {
        let movies = MockResponseCatalog.allMovies.filter { $0.title.localizedStandardContains(query) }
        return Self.page(of: movies, number: page)
    }

    func details(movieID: Movie.ID) async throws -> MovieDetails {
        let movie = MockResponseCatalog.allMovies.first { $0.id == movieID }
        guard let movie else {
            throw Failure.movieNotFound(movieID)
        }
        return MockResponseCatalog.details(for: movie)
    }

    private static func page(of movies: [Movie], number: Int) -> Page<Movie> {
        Page(number: number, items: number == 1 ? movies : [], totalPages: 1, totalResults: movies.count)
    }
}
