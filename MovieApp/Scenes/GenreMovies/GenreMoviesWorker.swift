nonisolated protocol IGenreMoviesWorker: Sendable {
    func fetchMovies(genreID: Genre.ID, page: Int) async throws -> Page<Movie>
}
