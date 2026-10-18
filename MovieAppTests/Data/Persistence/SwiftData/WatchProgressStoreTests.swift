import Foundation
@testable import MovieApp
import Testing

struct WatchProgressStoreTests {
    private let sut = WatchProgressStore(modelContainer: AppModelContainer(isStoredInMemoryOnly: true).modelContainer)
    private let guest = UserID(guestID: UUID())
    private let account = UserID(accountID: 548)
    private let older = WatchProgress.fixture(contentID: 1, lastWatchedAt: Date(timeIntervalSince1970: 1_000))
    private let newer = WatchProgress.fixture(contentID: 2, lastWatchedAt: Date(timeIntervalSince1970: 2_000))

    @Test
    func upsertInsertsThenUpdatesSameRecord() async throws {
        // Given
        _ = try await sut.upsert(older, for: guest)
        let rewatched = WatchProgress.fixture(contentID: 1, position: .seconds(120))

        // When
        let result = try await sut.upsert(rewatched, for: guest)

        // Assert
        #expect(result.value == [rewatched])
    }

    @Test
    func recordsAreMostRecentFirst() async throws {
        // Given
        _ = try await sut.upsert(older, for: guest)
        _ = try await sut.upsert(newer, for: guest)

        // When
        let records = try await sut.records(for: guest).value

        // Assert
        #expect(records == [newer, older])
    }

    @Test
    func recordsAreScopedPerUser() async throws {
        // Given
        _ = try await sut.upsert(older, for: guest)
        _ = try await sut.upsert(newer, for: account)

        // When
        let records = try await sut.records(for: account).value

        // Assert
        #expect(records == [newer])
    }

    @Test
    func progressForContentReadsOnlyThatUser() async throws {
        // Given
        _ = try await sut.upsert(older, for: guest)

        // When
        let progress = try await sut.progress(for: 1, mediaType: .movie, of: account)

        // Assert
        #expect(progress == nil)
    }

    @Test
    func removeAllClearsOnlyThatUser() async throws {
        // Given
        _ = try await sut.upsert(older, for: guest)
        _ = try await sut.upsert(newer, for: account)

        // When
        _ = try await sut.removeAll(for: guest)

        // Assert
        #expect(try await sut.records(for: guest).value.isEmpty)
        #expect(try await sut.records(for: account).value == [newer])
    }

    @Test
    func durationKeepsSeconds() async throws {
        // Given
        let progress = WatchProgress.fixture(contentID: 3, position: .milliseconds(1_500), duration: .seconds(153))

        // When
        _ = try await sut.upsert(progress, for: guest)

        // Assert
        let stored = try #require(try await sut.progress(for: 3, mediaType: .movie, of: guest))
        #expect(stored.position == .milliseconds(1_500))
        #expect(stored.duration == .seconds(153))
    }
}
