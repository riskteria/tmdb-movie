nonisolated protocol ISavedWorker: Sendable {
    // The current list first, then every change.
    func observeSavedMovies() async -> AsyncStream<[SavedMovie]>
    func removeMovie(_ movieID: Movie.ID) async throws
}

nonisolated struct SavedWorker {
    let savedMoviesRepository: any ISavedMoviesRepository
}

// MARK: - ISavedWorker
nonisolated extension SavedWorker: ISavedWorker {
    func observeSavedMovies() async -> AsyncStream<[SavedMovie]> {
        await savedMoviesRepository.changes
    }

    func removeMovie(_ movieID: Movie.ID) async throws {
        try await savedMoviesRepository.remove(movieID)
    }
}
