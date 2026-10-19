nonisolated protocol ISavedWorker: Sendable {
    // The current state first, then every change.
    func observeSavedMovies() async -> AsyncStream<AccountScoped<[SavedMovie]>>
    func removeMovie(_ movieID: Movie.ID) async throws
}

nonisolated struct SavedWorker {
    let savedMoviesRepository: any ISavedMoviesRepository
}

// MARK: - ISavedWorker
nonisolated extension SavedWorker: ISavedWorker {
    func observeSavedMovies() async -> AsyncStream<AccountScoped<[SavedMovie]>> {
        await savedMoviesRepository.changes
    }

    func removeMovie(_ movieID: Movie.ID) async throws {
        try await savedMoviesRepository.remove(movieID)
    }
}
