import Foundation
@testable import MovieApp
import Testing

struct SavedMoviesRepositoryTests {
    private let guest = UserID(guestID: UUID())
    private let account = UserID(accountID: 548)
    private let currentUser: CurrentUserProviderStub
    private let sut: any ISavedMoviesRepository

    init() {
        currentUser = CurrentUserProviderStub(userID: guest)
        sut = SavedMoviesRepository(
            container: AppModelContainer(isStoredInMemoryOnly: true),
            currentUser: currentUser,
            evictionPolicy: OldestSavedFirstEvictionPolicy()
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
        #expect(initial?.map(\.id) == [1])
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
        #expect(afterSave?.map(\.id) == [1])
    }

    @Test
    func switchingUserBroadcastsThatUsersList() async throws {
        // Given
        try await sut.save(.fixture(id: 1))
        var changes = await sut.changes.makeAsyncIterator()
        _ = await changes.next(isolation: #isolation)

        // When
        currentUser.send(account)

        // Assert
        let afterSwitch = await changes.next(isolation: #isolation)
        #expect(afterSwitch?.isEmpty == true)
    }

    @Test
    func containsFollowsCurrentUser() async throws {
        // Given
        try await sut.save(.fixture(id: 1))
        var changes = await sut.changes.makeAsyncIterator()
        _ = await changes.next(isolation: #isolation)
        currentUser.send(account)
        _ = await changes.next(isolation: #isolation)

        // When
        let containsGuestMovie = try await sut.contains(1)

        // Assert
        #expect(!containsGuestMovie)
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
        currentUser.send(account)
        _ = await changes.next(isolation: #isolation)
        try await sut.save(.fixture(id: 2))
        _ = await changes.next(isolation: #isolation)

        // When
        try await sut.removeAll()

        // Assert
        _ = await changes.next(isolation: #isolation)
        currentUser.send(guest)
        let guestMovies = await changes.next(isolation: #isolation)
        #expect(guestMovies?.map(\.id) == [1])
    }

    @Test
    func isPersistentComesFromContainer() {
        // Assert
        #expect(!sut.isPersistent)
    }
}
