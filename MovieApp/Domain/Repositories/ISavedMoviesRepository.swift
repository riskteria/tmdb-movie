nonisolated protocol ISavedMoviesRepository: Sendable {
    // Each subscriber gets the current list first, then every change.
    var changes: AsyncStream<[SavedMovie]> { get async }

    func all() async throws -> [SavedMovie]
    func contains(_ movieID: Movie.ID) async throws -> Bool
    func save(_ movie: Movie) async throws
    func remove(_ movieID: Movie.ID) async throws
    func removeAll() async throws
}
