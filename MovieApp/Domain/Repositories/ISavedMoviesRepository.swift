nonisolated protocol ISavedMoviesRepository: Sendable {
    // Each subscriber gets the current state first, then every change. While signed out, reads are empty and writes
    // do nothing.
    var changes: AsyncStream<AccountScoped<[SavedMovie]>> { get async }

    func all() async throws -> [SavedMovie]
    func contains(_ movieID: Movie.ID) async throws -> Bool
    func save(_ movie: Movie) async throws
    func remove(_ movieID: Movie.ID) async throws
    func removeAll() async throws
}
