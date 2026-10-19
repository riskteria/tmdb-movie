import Foundation
@testable import MovieApp
import Testing

struct MovieDetailWorkerTests {
    private let movie = Movie.fixture(id: 7)
    private let video = Video.fixture(key: "teaser-key")

    @Test
    func fetchDetailsReturnsDetailsForMovie() async throws {
        // Given
        let details = MovieDetails.fixture(movie: movie)
        let repository = MovieRepositoryStub(detailsByID: [7: details])
        let sut = makeSUT(movieRepository: repository)

        // When
        let result = try await sut.fetchDetails(movieID: 7)

        // Assert
        #expect(result == details)
        #expect(repository.calls == [.details(7)])
    }

    @Test
    func fetchDetailsRethrowsRepositoryError() async {
        // Given
        let sut = makeSUT()

        // When & Assert
        await #expect(throws: StubError.failed) {
            try await sut.fetchDetails(movieID: 7)
        }
    }

    @Test
    func saveMovieCallsRepository() async throws {
        // Given
        let repository = SavedMoviesRepositoryStub(save: .success(()))
        let sut = makeSUT(savedMoviesRepository: repository)

        // When
        try await sut.saveMovie(movie)

        // Assert
        #expect(repository.calls == [.save(7)])
    }

    @Test
    func removeMovieCallsRepository() async throws {
        // Given
        let repository = SavedMoviesRepositoryStub(remove: .success(()))
        let sut = makeSUT(savedMoviesRepository: repository)

        // When
        try await sut.removeMovie(7)

        // Assert
        #expect(repository.calls == [.remove(7)])
    }

    @Test
    func startWatchingStartsNewMovieAtZero() async throws {
        // Given
        let repository = WatchProgressRepositoryStub(result: .success([]), upsert: .success(()))
        let sut = makeSUT(watchProgressRepository: repository)

        // When
        try await sut.startWatching(movieID: 7, video: video)

        // Assert
        let progress = try #require(upsertedProgress(in: repository))
        #expect(progress.contentID == 7)
        #expect(progress.mediaType == .movie)
        #expect(progress.position == .zero)
        #expect(progress.duration == .zero)
    }

    @Test
    func startWatchingKeepsExistingPosition() async throws {
        // Given
        let existing = WatchProgress.fixture(contentID: 7, position: .seconds(95), duration: .seconds(153))
        let repository = WatchProgressRepositoryStub(result: .success([existing]), upsert: .success(()))
        let sut = makeSUT(watchProgressRepository: repository)

        // When
        try await sut.startWatching(movieID: 7, video: video)

        // Assert
        let progress = try #require(upsertedProgress(in: repository))
        #expect(progress.position == .seconds(95))
        #expect(progress.duration == .seconds(153))
        #expect(progress.lastWatchedAt > existing.lastWatchedAt)
    }

    @Test
    func startWatchingRecordsVideoKey() async throws {
        // Given
        let repository = WatchProgressRepositoryStub(result: .success([]), upsert: .success(()))
        let sut = makeSUT(watchProgressRepository: repository)

        // When
        try await sut.startWatching(movieID: 7, video: video)

        // Assert
        #expect(try #require(upsertedProgress(in: repository)).videoKey == "teaser-key")
    }

    @Test
    func observeSavedMoviesForwardsRepositoryChanges() async {
        // Given
        let savedMovies = [SavedMovie(movie: movie, savedAt: .now)]
        let sut = makeSUT(savedMoviesRepository: SavedMoviesRepositoryStub(savedMovies: savedMovies))

        // When
        let stream = await sut.observeSavedMovies()

        // Assert
        #expect(await stream.first { _ in true } == .signedIn(savedMovies))
    }
}

private extension MovieDetailWorkerTests {
    func makeSUT(
        movieRepository: any IMovieRepository = MovieRepositoryStub(),
        savedMoviesRepository: any ISavedMoviesRepository = SavedMoviesRepositoryStub(),
        watchProgressRepository: any IWatchProgressRepository = WatchProgressRepositoryStub(result: .success([]))
    ) -> any IMovieDetailWorker {
        MovieDetailWorker(
            movieRepository: movieRepository,
            savedMoviesRepository: savedMoviesRepository,
            watchProgressRepository: watchProgressRepository
        )
    }

    func upsertedProgress(in repository: WatchProgressRepositoryStub) -> WatchProgress? {
        repository.calls.compactMap { call -> WatchProgress? in
            guard case .upsert(let progress) = call else { return nil }
            return progress
        }.first
    }
}
