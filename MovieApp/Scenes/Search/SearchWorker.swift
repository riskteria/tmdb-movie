nonisolated protocol ISearchWorker: Sendable {
    func fetchGenres() async throws -> [Genre]
}

nonisolated struct SearchWorker {
    let genreRepository: any IGenreRepository
}

// MARK: - ISearchWorker
nonisolated extension SearchWorker: ISearchWorker {
    func fetchGenres() async throws -> [Genre] {
        try await genreRepository.movieGenres()
    }
}
