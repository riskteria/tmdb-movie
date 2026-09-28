nonisolated protocol MovieRepository: Sendable {
    func trending(window: TrendingWindow) async throws -> [Movie]
    func movies(in category: MovieCategory, page: Int) async throws -> Page<Movie>
    func discover(genreIDs: [Genre.ID], page: Int) async throws -> Page<Movie>
    func search(query: String, page: Int) async throws -> Page<Movie>
    func details(movieID: Movie.ID) async throws -> MovieDetails
}
