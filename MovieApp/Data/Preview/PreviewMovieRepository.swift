import Foundation

nonisolated struct PreviewMovieRepository {}

// MARK: - MovieRepository
nonisolated extension PreviewMovieRepository: MovieRepository {
    enum Failure: Error {
        case movieNotFound(Movie.ID)
    }

    func trending(window: TrendingWindow) async throws -> [Movie] {
        PreviewCatalog.trending
    }

    func movies(in category: MovieCategory, page: Int) async throws -> Page<Movie> {
        switch category {
        case .nowPlaying, .popular:
            Self.page(of: PreviewCatalog.popular, number: page)
        case .topRated:
            Self.page(of: PreviewCatalog.topRated, number: page)
        case .upcoming:
            Self.page(of: PreviewCatalog.upcoming, number: page)
        }
    }

    func discover(genreIDs: [Genre.ID], page: Int) async throws -> Page<Movie> {
        let movies = PreviewCatalog.allMovies.filter { movie in movie.genreIDs.contains { genreIDs.contains($0) } }
        return Self.page(of: movies, number: page)
    }

    func search(query: String, page: Int) async throws -> Page<Movie> {
        let movies = PreviewCatalog.allMovies.filter { $0.title.localizedStandardContains(query) }
        return Self.page(of: movies, number: page)
    }

    func details(movieID: Movie.ID) async throws -> MovieDetails {
        let movie = PreviewCatalog.allMovies.first { $0.id == movieID }
        guard let movie else {
            throw Failure.movieNotFound(movieID)
        }
        return PreviewCatalog.details(for: movie)
    }

    private static func page(of movies: [Movie], number: Int) -> Page<Movie> {
        Page(number: number, items: number == 1 ? movies : [], totalPages: 1, totalResults: movies.count)
    }
}
