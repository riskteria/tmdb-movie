nonisolated protocol IMovieDetailWorker: Sendable {
    func fetchDetails(movieID: Movie.ID) async throws -> MovieDetails
}

nonisolated struct MovieDetailWorker {
    let movieRepository: any IMovieRepository
}

// MARK: - IMovieDetailWorker
nonisolated extension MovieDetailWorker: IMovieDetailWorker {
    func fetchDetails(movieID: Movie.ID) async throws -> MovieDetails {
        try await movieRepository.details(movieID: movieID)
    }
}
