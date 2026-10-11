import Foundation
@testable import MovieApp
import Testing

struct WatchProgressRepositoryTests {
    private let older = WatchProgress.fixture(contentID: 1, lastWatchedAt: Date(timeIntervalSince1970: 1_000))
    private let newer = WatchProgress.fixture(contentID: 2, lastWatchedAt: Date(timeIntervalSince1970: 2_000))

    @Test
    func recentListsMostRecentlyWatchedFirst() async throws {
        // Given
        let sut: any IWatchProgressRepository = WatchProgressRepository(records: [older, newer])

        // When
        let records = try await sut.recent(limit: 10)

        // Assert
        #expect(records == [newer, older])
    }

    @Test
    func recentReturnsAtMostTheLimit() async throws {
        // Given
        let sut: any IWatchProgressRepository = WatchProgressRepository(records: [older, newer])

        // When
        let records = try await sut.recent(limit: 1)

        // Assert
        #expect(records == [newer])
    }

    @Test
    func upsertReplacesTheRecordAndMovesItToTheFront() async throws {
        // Given
        let sut: any IWatchProgressRepository = WatchProgressRepository(records: [older, newer])
        let rewatched = WatchProgress.fixture(contentID: 1, position: .seconds(120))

        // When
        try await sut.upsert(rewatched)

        // Assert
        #expect(try await sut.recent(limit: 10) == [rewatched, newer])
    }

    @Test
    func upsertKeepsTheRecordOfTheSameIDForAnotherMediaType() async throws {
        // Given
        let sut: any IWatchProgressRepository = WatchProgressRepository(records: [older])
        let show = WatchProgress.fixture(contentID: 1, mediaType: .tvShow)

        // When
        try await sut.upsert(show)

        // Assert
        #expect(try await sut.recent(limit: 10) == [show, older])
    }

    @Test
    func progressFindsTheRecordForContent() async throws {
        // Given
        let sut: any IWatchProgressRepository = WatchProgressRepository(records: [older, newer])

        // When
        let progress = try await sut.progress(for: 2, mediaType: .movie)

        // Assert
        #expect(progress == newer)
    }

    @Test
    func progressIsNilForUnwatchedContent() async throws {
        // Given
        let sut: any IWatchProgressRepository = WatchProgressRepository(records: [older])

        // When
        let progress = try await sut.progress(for: 99, mediaType: .movie)

        // Assert
        #expect(progress == nil)
    }

    @Test
    func progressIsNilForTheSameIDOfAnotherMediaType() async throws {
        // Given
        let sut: any IWatchProgressRepository = WatchProgressRepository(records: [older])

        // When
        let progress = try await sut.progress(for: 1, mediaType: .tvShow)

        // Assert
        #expect(progress == nil)
    }

    @Test
    func changesStartWithTheCurrentRecords() async {
        // Given
        let sut: any IWatchProgressRepository = WatchProgressRepository(records: [older])
        var changes = await sut.changes.makeAsyncIterator()

        // When
        let initial = await changes.next(isolation: #isolation)

        // Assert
        #expect(initial == [older])
    }

    @Test
    func upsertSendsTheUpdatedRecords() async throws {
        // Given
        let sut: any IWatchProgressRepository = WatchProgressRepository(records: [older])
        var changes = await sut.changes.makeAsyncIterator()
        _ = await changes.next(isolation: #isolation)

        // When
        try await sut.upsert(newer)
        let afterUpsert = await changes.next(isolation: #isolation)

        // Assert
        #expect(afterUpsert == [newer, older])
    }

    @Test
    func removeAllSendsAnEmptyList() async throws {
        // Given
        let sut: any IWatchProgressRepository = WatchProgressRepository(records: [older])
        var changes = await sut.changes.makeAsyncIterator()
        _ = await changes.next(isolation: #isolation)

        // When
        try await sut.removeAll()
        let afterRemoval = await changes.next(isolation: #isolation)

        // Assert
        #expect(afterRemoval?.isEmpty == true)
    }
}
