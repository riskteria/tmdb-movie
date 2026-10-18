import Foundation
@testable import MovieApp
import Testing

struct WatchProgressRepositoryTests {
    private let guest = UserID(guestID: UUID())
    private let account = UserID(accountID: 548)
    private let older = WatchProgress.fixture(contentID: 1, lastWatchedAt: Date(timeIntervalSince1970: 1_000))
    private let newer = WatchProgress.fixture(contentID: 2, lastWatchedAt: Date(timeIntervalSince1970: 2_000))
    private let currentUser: CurrentUserProviderStub
    private let sut: any IWatchProgressRepository

    init() {
        currentUser = CurrentUserProviderStub(userID: guest)
        sut = WatchProgressRepository(
            container: AppModelContainer(isStoredInMemoryOnly: true),
            currentUser: currentUser
        )
    }

    @Test
    func upsertMovesRecordToFront() async throws {
        // Given
        try await sut.upsert(older)
        try await sut.upsert(newer)
        let rewatched = WatchProgress.fixture(contentID: 1, lastWatchedAt: Date(timeIntervalSince1970: 3_000))

        // When
        try await sut.upsert(rewatched)

        // Assert
        #expect(try await sut.recent(limit: 10) == [rewatched, newer])
    }

    @Test
    func recentRespectsLimit() async throws {
        // Given
        try await sut.upsert(older)
        try await sut.upsert(newer)

        // When
        let records = try await sut.recent(limit: 1)

        // Assert
        #expect(records == [newer])
    }

    @Test
    func progressReadsCurrentUser() async throws {
        // Given
        try await sut.upsert(older)

        // When
        let progress = try await sut.progress(for: 1, mediaType: .movie)

        // Assert
        #expect(progress == older)
    }

    @Test
    func switchingUserBroadcastsThatUsersRecords() async throws {
        // Given
        try await sut.upsert(older)
        var changes = await sut.changes.makeAsyncIterator()
        _ = await changes.next(isolation: #isolation)

        // When
        currentUser.send(account)

        // Assert
        let afterSwitch = await changes.next(isolation: #isolation)
        #expect(afterSwitch?.isEmpty == true)
    }

    @Test
    func removeAllEmptiesOnlyCurrentUser() async throws {
        // Given
        try await sut.upsert(older)
        var changes = await sut.changes.makeAsyncIterator()
        _ = await changes.next(isolation: #isolation)
        currentUser.send(account)
        _ = await changes.next(isolation: #isolation)
        try await sut.upsert(newer)
        _ = await changes.next(isolation: #isolation)

        // When
        try await sut.removeAll()

        // Assert
        _ = await changes.next(isolation: #isolation)
        currentUser.send(guest)
        let guestRecords = await changes.next(isolation: #isolation)
        #expect(guestRecords == [older])
    }
}
