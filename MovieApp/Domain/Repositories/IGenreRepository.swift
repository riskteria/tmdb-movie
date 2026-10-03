nonisolated protocol IGenreRepository: Sendable {
    func movieGenres() async throws -> [Genre]
}
