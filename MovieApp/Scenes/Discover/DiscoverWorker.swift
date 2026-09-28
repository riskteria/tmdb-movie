nonisolated protocol IDiscoverWorker: Sendable {
    func fetchGenres() async throws -> [Genre]
}

nonisolated struct DiscoverWorker {
    let genreRepository: any GenreRepository
}

// MARK: - IDiscoverWorker
nonisolated extension DiscoverWorker: IDiscoverWorker {
    func fetchGenres() async throws -> [Genre] {
        try await genreRepository.movieGenres()
    }
}
