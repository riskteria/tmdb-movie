nonisolated protocol IGenreMoviesWorker: Sendable {
    func fetchMovies(genreID: Genre.ID, page: Int) async throws -> Page<Movie>
}

nonisolated struct GenreMoviesWorker {
    let movieRepository: any IMovieRepository
}

// MARK: - IGenreMoviesWorker
nonisolated extension GenreMoviesWorker: IGenreMoviesWorker {
    func fetchMovies(genreID: Genre.ID, page: Int) async throws -> Page<Movie> {
        try await movieRepository.discover(genreIDs: [genreID], page: page)
    }
}
