import Foundation
@testable import MovieApp
import Testing

struct WatchProgressRepositoryTests {
    private let account: Account.ID = 548
    private let otherAccount: Account.ID = 549
    private let older = WatchProgress.fixture(contentID: 1, lastWatchedAt: Date(timeIntervalSince1970: 1_000))
    private let newer = WatchProgress.fixture(contentID: 2, lastWatchedAt: Date(timeIntervalSince1970: 2_000))
    private let currentUser: CurrentUserProviderStub
    private let sut: any IWatchProgressRepository

    init() {
        currentUser = CurrentUserProviderStub(accountID: account)
        sut = WatchProgressRepository(
            container: AppModelContainer(temporaryStoreID: UUID()),
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
    func changesStartsSignedOutWithoutAccount() async {
        // Given
        let signedOutSUT = makeSUT(currentUser: CurrentUserProviderStub(accountID: nil))
        var changes = await signedOutSUT.changes.makeAsyncIterator()

        // When
        let initial = await changes.next(isolation: #isolation)

        // Assert
        #expect(initial == .signedOut)
    }

    @Test
    func switchingUserBroadcastsThatUsersRecords() async throws {
        // Given
        try await sut.upsert(older)
        var changes = await sut.changes.makeAsyncIterator()
        _ = await changes.next(isolation: #isolation)

        // When
        currentUser.send(otherAccount)

        // Assert
        let afterSwitch = await changes.next(isolation: #isolation)
        #expect(afterSwitch == .signedIn([]))
    }

    @Test
    func signOutBroadcastsSignedOut() async throws {
        // Given
        try await sut.upsert(older)
        var changes = await sut.changes.makeAsyncIterator()
        _ = await changes.next(isolation: #isolation)

        // When
        currentUser.send(nil)

        // Assert
        let afterSignOut = await changes.next(isolation: #isolation)
        #expect(afterSignOut == .signedOut)
    }

    @Test
    func writesWhileSignedOutDoNothing() async throws {
        // Given
        let signedOutUser = CurrentUserProviderStub(accountID: nil)
        let signedOutSUT = makeSUT(currentUser: signedOutUser)
        var changes = await signedOutSUT.changes.makeAsyncIterator()
        _ = await changes.next(isolation: #isolation)

        // When
        try await signedOutSUT.upsert(older)

        // Assert
        signedOutUser.send(account)
        let afterSignIn = await changes.next(isolation: #isolation)
        #expect(afterSignIn == .signedIn([]))
    }

    @Test
    func signingInAgainRestoresList() async throws {
        // Given
        try await sut.upsert(older)
        var changes = await sut.changes.makeAsyncIterator()
        _ = await changes.next(isolation: #isolation)
        currentUser.send(nil)
        _ = await changes.next(isolation: #isolation)

        // When
        currentUser.send(account)

        // Assert
        let afterSignIn = await changes.next(isolation: #isolation)
        #expect(afterSignIn == .signedIn([older]))
    }

    @Test
    func removeAllEmptiesOnlyCurrentUser() async throws {
        // Given
        try await sut.upsert(older)
        var changes = await sut.changes.makeAsyncIterator()
        _ = await changes.next(isolation: #isolation)
        currentUser.send(otherAccount)
        _ = await changes.next(isolation: #isolation)
        try await sut.upsert(newer)
        _ = await changes.next(isolation: #isolation)

        // When
        try await sut.removeAll()

        // Assert
        _ = await changes.next(isolation: #isolation)
        currentUser.send(account)
        let firstAccountsRecords = await changes.next(isolation: #isolation)
        #expect(firstAccountsRecords == .signedIn([older]))
    }
}

private extension WatchProgressRepositoryTests {
    func makeSUT(currentUser: CurrentUserProviderStub) -> any IWatchProgressRepository {
        WatchProgressRepository(
            container: AppModelContainer(temporaryStoreID: UUID()),
            currentUser: currentUser
        )
    }
}
