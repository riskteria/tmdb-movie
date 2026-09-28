@testable import MovieApp
import Testing

struct HomeWorkerTests {
    @Test
    func fetchTrendingMoviesReturnsMoviesForWindow() async throws {
        // Given
        let movies = [Movie.fixture(id: 1), Movie.fixture(id: 2)]
        let repository = MovieRepositoryStub(trendingMovies: movies)
        let sut = makeSUT(movieRepository: repository)

        // When
        let result = try await sut.fetchTrendingMovies(window: .day)

        // Assert
        #expect(result == movies)
        #expect(repository.calls == [.trending(.day)])
    }

    @Test
    func fetchMoviesReturnsPageForCategory() async throws {
        // Given
        let page = Page.fixture([.fixture(id: 1)])
        let repository = MovieRepositoryStub(moviePage: page)
        let sut = makeSUT(movieRepository: repository)

        // When
        let result = try await sut.fetchMovies(in: .topRated, page: 2)

        // Assert
        #expect(result == page)
        #expect(repository.calls == [.movies(.topRated, page: 2)])
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
        let progressRepository = WatchProgressRepositoryStub(records: [])
        let sut = makeSUT(watchProgressRepository: progressRepository)

        // When
        _ = try await sut.fetchContinueWatching(limit: 10)

        // Assert
        #expect(progressRepository.requestedLimits == [10])
    }

    private func makeSUT(
        movieRepository: MovieRepositoryStub = MovieRepositoryStub(),
        genreRepository: GenreRepositoryStub = GenreRepositoryStub(result: .success([])),
        watchProgressRepository: WatchProgressRepositoryStub = WatchProgressRepositoryStub(records: [])
    ) -> HomeWorker {
        HomeWorker(
            movieRepository: movieRepository,
            genreRepository: genreRepository,
            watchProgressRepository: watchProgressRepository
        )
    }

    private func makeSUT(records: [WatchProgress], detailsFor movieIDs: [Movie.ID]) -> HomeWorker {
        let details = movieIDs.map { MovieDetails.fixture(movie: .fixture(id: $0)) }
        let detailsByID = Dictionary(uniqueKeysWithValues: details.map { ($0.movie.id, $0) })
        return makeSUT(
            movieRepository: MovieRepositoryStub(detailsByID: detailsByID),
            watchProgressRepository: WatchProgressRepositoryStub(records: records)
        )
    }
}
