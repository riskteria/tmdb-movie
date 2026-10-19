import Foundation
@testable import MovieApp
import Testing

struct SavedMoviesRepositoryTests {
    private let account: Account.ID = 548
    private let otherAccount: Account.ID = 549
    private let currentUser: CurrentUserProviderStub
    private let sut: any ISavedMoviesRepository

    init() {
        currentUser = CurrentUserProviderStub(accountID: account)
        sut = SavedMoviesRepository(
            container: AppModelContainer(temporaryStoreID: UUID()),
            currentUser: currentUser,
            evictionPolicy: SavedFirstEvictionPolicy()
        )
    }

    @Test
    func changesStartsWithCurrentUsersMovies() async throws {
        // Given
        try await sut.save(.fixture(id: 1))
        var changes = await sut.changes.makeAsyncIterator()

        // When
        let initial = await changes.next(isolation: #isolation)

        // Assert
        #expect(initial?.movieIDs == [1])
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
    func saveBroadcastsNewList() async throws {
        // Given
        var changes = await sut.changes.makeAsyncIterator()
        _ = await changes.next(isolation: #isolation)

        // When
        try await sut.save(.fixture(id: 1))

        // Assert
        let afterSave = await changes.next(isolation: #isolation)
        #expect(afterSave?.movieIDs == [1])
    }

    @Test
    func switchingUserBroadcastsThatUsersList() async throws {
        // Given
        try await sut.save(.fixture(id: 1))
        var changes = await sut.changes.makeAsyncIterator()
        _ = await changes.next(isolation: #isolation)

        // When
        currentUser.send(otherAccount)

        // Assert
        let afterSwitch = await changes.next(isolation: #isolation)
        #expect(afterSwitch?.movieIDs?.isEmpty == true)
    }

    @Test
    func signOutBroadcastsSignedOut() async throws {
        // Given
        try await sut.save(.fixture(id: 1))
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
        try await signedOutSUT.save(.fixture(id: 1))

        // Assert
        signedOutUser.send(account)
        let afterSignIn = await changes.next(isolation: #isolation)
        #expect(afterSignIn?.movieIDs?.isEmpty == true)
    }

    @Test
    func signingInAgainRestoresList() async throws {
        // Given
        try await sut.save(.fixture(id: 1))
        var changes = await sut.changes.makeAsyncIterator()
        _ = await changes.next(isolation: #isolation)
        currentUser.send(nil)
        _ = await changes.next(isolation: #isolation)

        // When
        currentUser.send(account)

        // Assert
        let afterSignIn = await changes.next(isolation: #isolation)
        #expect(afterSignIn?.movieIDs == [1])
    }

    @Test
    func containsFollowsCurrentUser() async throws {
        // Given
        try await sut.save(.fixture(id: 1))
        var changes = await sut.changes.makeAsyncIterator()
        _ = await changes.next(isolation: #isolation)
        currentUser.send(otherAccount)
        _ = await changes.next(isolation: #isolation)

        // When
        let containsFirstAccountsMovie = try await sut.contains(1)

        // Assert
        #expect(!containsFirstAccountsMovie)
    }

    @Test
    func fiftyFirstSaveEvictsOldest() async throws {
        // Given
        for movieID in 1...SavedMovie.capacity {
            try await sut.save(.fixture(id: movieID))
        }

        // When
        try await sut.save(.fixture(id: 51))

        // Assert
        let movieIDs = try await sut.all().map(\.id)
        #expect(movieIDs.count == SavedMovie.capacity)
        #expect(movieIDs.first == 51)
        #expect(!movieIDs.contains(1))
    }

    @Test
    func removeAllEmptiesOnlyCurrentUser() async throws {
        // Given
        try await sut.save(.fixture(id: 1))
        var changes = await sut.changes.makeAsyncIterator()
        _ = await changes.next(isolation: #isolation)
        currentUser.send(otherAccount)
        _ = await changes.next(isolation: #isolation)
        try await sut.save(.fixture(id: 2))
        _ = await changes.next(isolation: #isolation)

        // When
        try await sut.removeAll()

        // Assert
        _ = await changes.next(isolation: #isolation)
        currentUser.send(account)
        let firstAccountsMovies = await changes.next(isolation: #isolation)
        #expect(firstAccountsMovies?.movieIDs == [1])
    }
}

private extension SavedMoviesRepositoryTests {
    func makeSUT(currentUser: CurrentUserProviderStub) -> any ISavedMoviesRepository {
        SavedMoviesRepository(
            container: AppModelContainer(temporaryStoreID: UUID()),
            currentUser: currentUser,
            evictionPolicy: SavedFirstEvictionPolicy()
        )
    }
}

private extension AccountScoped<[SavedMovie]> {
    var movieIDs: [Movie.ID]? {
        guard case .signedIn(let savedMovies) = self else { return nil }
        return savedMovies.map(\.id)
    }
}
