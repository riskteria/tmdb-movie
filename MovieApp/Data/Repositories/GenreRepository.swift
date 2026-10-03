nonisolated struct GenreRepository {}

// MARK: - IGenreRepository
nonisolated extension GenreRepository: IGenreRepository {
    func movieGenres() async throws -> [Genre] {
        MockResponseCatalog.genres
    }
}
