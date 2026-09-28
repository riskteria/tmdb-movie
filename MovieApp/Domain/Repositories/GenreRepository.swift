nonisolated protocol GenreRepository: Sendable {
    func movieGenres() async throws -> [Genre]
}
