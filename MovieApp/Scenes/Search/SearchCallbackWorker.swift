nonisolated protocol ISearchCallbackWorker: Sendable {
    func fetchGenres(completion: @escaping @Sendable (Result<[Genre], any Error>) -> Void)
}

nonisolated struct SearchCallbackWorker {
    let genreRepository: any ICallbackGenreRepository
}

// MARK: - ISearchCallbackWorker
nonisolated extension SearchCallbackWorker: ISearchCallbackWorker {
    func fetchGenres(completion: @escaping @Sendable (Result<[Genre], any Error>) -> Void) {
        genreRepository.movieGenres(completion: completion)
    }
}
