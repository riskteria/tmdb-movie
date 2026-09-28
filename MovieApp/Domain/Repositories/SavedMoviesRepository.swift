nonisolated protocol SavedMoviesRepository: Sendable {
    // False after the store failed to open and the repository fell back to memory.
    var isPersistent: Bool { get }
    // Each subscriber gets the current list first, then every change.
    var changes: AsyncStream<[SavedMovie]> { get async }

    func all() async throws -> [SavedMovie]
    func contains(_ movieID: Movie.ID) async throws -> Bool
    func save(_ movie: Movie) async throws
    func remove(_ movieID: Movie.ID) async throws
    func removeAll() async throws
}
