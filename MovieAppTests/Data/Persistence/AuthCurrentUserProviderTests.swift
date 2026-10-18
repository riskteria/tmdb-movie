import Foundation
@testable import MovieApp
import Testing

struct AuthCurrentUserProviderTests {
    private let guestID = UserID(guestID: UUID())
    private let account = Account(id: 548, username: "moviefan", name: "Movie Fan", avatarPath: nil)

    @Test
    func signedOutMapsToGuestID() async {
        // Given
        let sut: any CurrentUserProvider = makeSUT(states: [.signedOut])

        // When
        let userID = await sut.userIDs.first { _ in true }

        // Assert
        #expect(userID == guestID)
    }

    @Test
    func signedInMapsToAccountID() async {
        // Given
        let sut: any CurrentUserProvider = makeSUT(states: [.signedIn(account)])

        // When
        let userID = await sut.userIDs.first { _ in true }

        // Assert
        #expect(userID == UserID(accountID: 548))
    }

    @Test
    func refreshedAccountYieldsOnce() async {
        // Given
        let renamed = Account(id: 548, username: "moviefan", name: "Renamed Fan", avatarPath: nil)
        let sut: any CurrentUserProvider = makeSUT(states: [.signedIn(account), .signedIn(renamed)])
        var userIDs: [UserID] = []

        // When
        for await userID in await sut.userIDs {
            userIDs.append(userID)
        }

        // Assert
        #expect(userIDs == [UserID(accountID: 548)])
    }
}

private extension AuthCurrentUserProviderTests {
    func makeSUT(states: [AuthState]) -> AuthCurrentUserProvider {
        AuthCurrentUserProvider(authRepository: AuthRepositoryStub(states: states), guestID: guestID)
    }
}
