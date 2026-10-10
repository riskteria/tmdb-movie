@testable import MovieApp
import Testing

struct HomeWorkerTests {
    @Test
    func fetchTrendingMoviesReturnsMoviesForWindow() async throws {
        // Given
        let movies = [Movie.fixture(id: 1), Movie.fixture(id: 2)]
        let repository = MovieRepositoryStub(trending: .success(movies))
        let sut = makeSUT(movieRepository: repository)

        // When
        let result = try await sut.fetchTrendingMovies(window: .day)

        // Assert
        #expect(result == movies)
        #expect(repository.calls == [.trending(.day)])
    }

    @Test
    func fetchTrendingMoviesRethrowsRepositoryError() async {
        // Given
        let sut = makeSUT(movieRepository: MovieRepositoryStub(trending: .failure(StubError.failed)))

        // When & Assert
        await #expect(throws: StubError.failed) {
            try await sut.fetchTrendingMovies(window: .day)
        }
    }

    @Test
    func fetchMoviesReturnsPageForCategory() async throws {
        // Given
        let page = Page.fixture([.fixture(id: 1)])
        let repository = MovieRepositoryStub(movies: .success(page))
        let sut = makeSUT(movieRepository: repository)

        // When
        let result = try await sut.fetchMovies(in: .topRated, page: 2)

        // Assert
        #expect(result == page)
        #expect(repository.calls == [.movies(.topRated, page: 2)])
    }

    @Test
    func fetchMoviesRethrowsRepositoryError() async {
        // Given
        let sut = makeSUT(movieRepository: MovieRepositoryStub(movies: .failure(StubError.failed)))

        // When & Assert
        await #expect(throws: StubError.failed) {
            try await sut.fetchMovies(in: .popular, page: 1)
        }
    }

    @Test
    func fetchGenresReturnsMovieGenres() async throws {
        // Given
        let genres = [Genre.scienceFiction, Genre.drama]
        let sut = makeSUT(genreRepository: GenreRepositoryStub(result: .success(genres)))

        // When
        let result = try await sut.fetchGenres()

        // Assert
        #expect(result == genres)
    }

    @Test
    func fetchGenresRethrowsRepositoryError() async {
        // Given
        let sut = makeSUT(genreRepository: GenreRepositoryStub(result: .failure(StubError.failed)))

        // When & Assert
        await #expect(throws: StubError.failed) {
            try await sut.fetchGenres()
        }
    }

    @Test
    func fetchContinueWatchingMergesProgressWithDetailsInRecencyOrder() async throws {
        // Given
        let recent = WatchProgress.fixture(contentID: 1, position: .seconds(30), duration: .seconds(100))
        let older = WatchProgress.fixture(contentID: 2, position: .seconds(10), duration: .seconds(100))
        let sut = makeSUT(records: [recent, older], detailsFor: [1, 2])

        // When
        let items = try await sut.fetchContinueWatching(limit: 10)

        // Assert
        #expect(items.map(\.progress) == [recent, older])
        #expect(items.map(\.details.movie.id) == [1, 2])
    }

    @Test
    func fetchContinueWatchingSkipsFinishedProgress() async throws {
        // Given
        let finished = WatchProgress.fixture(contentID: 1, position: .seconds(98), duration: .seconds(100))
        let unfinished = WatchProgress.fixture(contentID: 2, position: .seconds(10), duration: .seconds(100))
        let sut = makeSUT(records: [finished, unfinished], detailsFor: [1, 2])

        // When
        let items = try await sut.fetchContinueWatching(limit: 10)

        // Assert
        #expect(items.map(\.details.movie.id) == [2])
    }

    @Test
    func fetchContinueWatchingSkipsMoviesWhoseDetailsFailToLoad() async throws {
        // Given
        let first = WatchProgress.fixture(contentID: 1)
        let second = WatchProgress.fixture(contentID: 2)
        let sut = makeSUT(records: [first, second], detailsFor: [2])

        // When
        let items = try await sut.fetchContinueWatching(limit: 10)

        // Assert
        #expect(items.map(\.details.movie.id) == [2])
    }

    @Test
    func fetchContinueWatchingRequestsTheGivenLimit() async throws {
        // Given
        let progressRepository = WatchProgressRepositoryStub(result: .success([]))
        let sut = makeSUT(watchProgressRepository: progressRepository)

        // When
        _ = try await sut.fetchContinueWatching(limit: 10)

        // Assert
        #expect(progressRepository.requestedLimits == [10])
    }

    @Test
    func fetchContinueWatchingRethrowsProgressError() async {
        // Given
        let progressRepository = WatchProgressRepositoryStub(result: .failure(StubError.failed))
        let sut = makeSUT(watchProgressRepository: progressRepository)

        // When & Assert
        await #expect(throws: StubError.failed) {
            try await sut.fetchContinueWatching(limit: 10)
        }
    }

    private func makeSUT(
        movieRepository: any IMovieRepository = MovieRepositoryStub(),
        genreRepository: any IGenreRepository = GenreRepositoryStub(result: .success([])),
        watchProgressRepository: any IWatchProgressRepository = WatchProgressRepositoryStub(
            result: .success([])
        )
    ) -> any IHomeWorker {
        HomeWorker(
            movieRepository: movieRepository,
            genreRepository: genreRepository,
            watchProgressRepository: watchProgressRepository
        )
    }

    private func makeSUT(records: [WatchProgress], detailsFor movieIDs: [Movie.ID]) -> any IHomeWorker {
        let details = movieIDs.map { MovieDetails.fixture(movie: .fixture(id: $0)) }
        let detailsByID = Dictionary(uniqueKeysWithValues: details.map { ($0.movie.id, $0) })
        return makeSUT(
            movieRepository: MovieRepositoryStub(detailsByID: detailsByID),
            watchProgressRepository: WatchProgressRepositoryStub(result: .success(records))
        )
    }
}
