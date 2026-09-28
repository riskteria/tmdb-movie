nonisolated protocol ISavedWorker: Sendable {
    // The current list first, then every change.
    func observeSavedMovies() async -> AsyncStream<[SavedMovie]>
}

nonisolated struct SavedWorker {
    let savedMoviesRepository: any SavedMoviesRepository
}

// MARK: - ISavedWorker
nonisolated extension SavedWorker: ISavedWorker {
    func observeSavedMovies() async -> AsyncStream<[SavedMovie]> {
        await savedMoviesRepository.changes
    }
}
