nonisolated struct PreviewGenreRepository {}

// MARK: - GenreRepository
nonisolated extension PreviewGenreRepository: GenreRepository {
    func movieGenres() async throws -> [Genre] {
        PreviewCatalog.genres
    }
}
