nonisolated protocol ICallbackGenreRepository: Sendable {
    func movieGenres(completion: @escaping @Sendable (Result<[Genre], any Error>) -> Void)
}
