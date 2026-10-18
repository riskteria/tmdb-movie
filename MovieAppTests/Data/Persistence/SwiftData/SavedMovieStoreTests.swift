import Foundation
@testable import MovieApp
import Synchronization
import Testing

struct SavedMovieStoreTests {
    private let sut = SavedMovieStore(modelContainer: AppModelContainer(isStoredInMemoryOnly: true).modelContainer)
    private let guest = UserID(guestID: UUID())
    private let account = UserID(accountID: 548)
    private let keepEverything = OldestSavedFirstEvictionPolicy()

    @Test
    func saveThenMoviesReturnsNewestFirst() async throws {
        // Given
        _ = try await sut.save(.fixture(id: 1), for: guest, evictionPolicy: keepEverything)
        _ = try await sut.save(.fixture(id: 2), for: guest, evictionPolicy: keepEverything)

        // When
        let movies = try await sut.movies(for: guest).value

        // Assert
        #expect(movies.map(\.id) == [2, 1])
    }

    @Test
    func moviesAreScopedPerUser() async throws {
        // Given
        _ = try await sut.save(.fixture(id: 1), for: guest, evictionPolicy: keepEverything)
        _ = try await sut.save(.fixture(id: 2), for: account, evictionPolicy: keepEverything)

        // When
        let movies = try await sut.movies(for: account).value

        // Assert
        #expect(movies.map(\.id) == [2])
    }

    @Test
    func resavingRefreshesSavedAtWithoutDuplicate() async throws {
        // Given
        _ = try await sut.save(.fixture(id: 1), for: guest, evictionPolicy: keepEverything)
        _ = try await sut.save(.fixture(id: 2), for: guest, evictionPolicy: keepEverything)

        // When
        let result = try await sut.save(.fixture(id: 1), for: guest, evictionPolicy: keepEverything)

        // Assert
        #expect(result.value.map(\.id) == [1, 2])
    }

    @Test
    func saveAsksPolicyAndDeletesItsChoice() async throws {
        // Given
        _ = try await sut.save(.fixture(id: 1), for: guest, evictionPolicy: keepEverything)
        let policy = EvictionPolicySpy(evictedIDs: [1])

        // When
        let result = try await sut.save(.fixture(id: 2), for: guest, evictionPolicy: policy)

        // Assert
        #expect(policy.requests == [EvictionPolicySpy.Request(movieIDs: [2, 1], capacity: SavedMovie.capacity)])
        #expect(result.value.map(\.id) == [2])
    }

    @Test
    func removeDeletesOnlyThatUsersMovie() async throws {
        // Given
        _ = try await sut.save(.fixture(id: 1), for: guest, evictionPolicy: keepEverything)
        _ = try await sut.save(.fixture(id: 1), for: account, evictionPolicy: keepEverything)

        // When
        _ = try await sut.remove(1, for: guest)

        // Assert
        #expect(try await sut.movies(for: guest).value.isEmpty)
        #expect(try await sut.movies(for: account).value.map(\.id) == [1])
    }

    @Test
    func removeAllClearsOnlyThatUser() async throws {
        // Given
        _ = try await sut.save(.fixture(id: 1), for: guest, evictionPolicy: keepEverything)
        _ = try await sut.save(.fixture(id: 2), for: account, evictionPolicy: keepEverything)

        // When
        _ = try await sut.removeAll(for: account)

        // Assert
        #expect(try await sut.movies(for: account).value.isEmpty)
        #expect(try await sut.movies(for: guest).value.map(\.id) == [1])
    }

    @Test
    func everyWriteIncreasesRevision() async throws {
        // Given
        let saved = try await sut.save(.fixture(id: 1), for: guest, evictionPolicy: keepEverything)

        // When
        let removed = try await sut.remove(1, for: guest)

        // Assert
        #expect(removed.revision > saved.revision)
    }

    @Test
    func recordKeepsEveryMovieField() async throws {
        // Given
        let movie = Movie.fixture(
            id: 7,
            title: "Dune: Part Two",
            posterPath: ImagePath(rawValue: "/poster.jpg"),
            backdropPath: ImagePath(rawValue: "/backdrop.jpg"),
            genreIDs: [878, 12],
            voteAverage: 8.2
        )

        // When
        _ = try await sut.save(movie, for: guest, evictionPolicy: keepEverything)

        // Assert
        #expect(try await sut.movies(for: guest).value.map(\.movie) == [movie])
    }
}

private final class EvictionPolicySpy: SavedMoviesEvictionPolicy {
    struct Request: Equatable {
        let movieIDs: [Movie.ID]
        let capacity: Int
    }

    private let evictedIDs: [Movie.ID]
    private let recordedRequests = Mutex<[Request]>([])

    var requests: [Request] {
        recordedRequests.withLock { $0 }
    }

    init(evictedIDs: [Movie.ID]) {
        self.evictedIDs = evictedIDs
    }

    func moviesToEvict(from savedMovies: [SavedMovie], capacity: Int) -> [Movie.ID] {
        recordedRequests.withLock { $0.append(Request(movieIDs: savedMovies.map(\.id), capacity: capacity)) }
        return evictedIDs
    }
}
