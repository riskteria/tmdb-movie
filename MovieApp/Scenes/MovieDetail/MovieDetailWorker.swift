import Foundation

nonisolated protocol IMovieDetailWorker: Sendable {
    func fetchDetails(movieID: Movie.ID) async throws -> MovieDetails
    func observeSavedMovies() async -> AsyncStream<AccountScoped<[SavedMovie]>>
    func saveMovie(_ movie: Movie) async throws
    func removeMovie(_ movieID: Movie.ID) async throws
    func startWatching(movieID: Movie.ID, video: Video) async throws
}

nonisolated struct MovieDetailWorker {
    let movieRepository: any IMovieRepository
    let savedMoviesRepository: any ISavedMoviesRepository
    let watchProgressRepository: any IWatchProgressRepository
}

// MARK: - IMovieDetailWorker
nonisolated extension MovieDetailWorker: IMovieDetailWorker {
    func fetchDetails(movieID: Movie.ID) async throws -> MovieDetails {
        try await movieRepository.details(movieID: movieID)
    }

    func observeSavedMovies() async -> AsyncStream<AccountScoped<[SavedMovie]>> {
        await savedMoviesRepository.changes
    }

    func saveMovie(_ movie: Movie) async throws {
        try await savedMoviesRepository.save(movie)
    }

    func removeMovie(_ movieID: Movie.ID) async throws {
        try await savedMoviesRepository.remove(movieID)
    }

    func startWatching(movieID: Movie.ID, video: Video) async throws {
        let existing = try await watchProgressRepository.progress(for: movieID, mediaType: .movie)
        try await watchProgressRepository.upsert(
            WatchProgress(
                contentID: movieID,
                mediaType: .movie,
                position: existing?.position ?? .zero,
                duration: existing?.duration ?? .zero,
                videoKey: video.key,
                lastWatchedAt: .now
            )
        )
    }
}
