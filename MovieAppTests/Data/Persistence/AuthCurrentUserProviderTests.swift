@testable import MovieApp
import Testing

struct AuthCurrentUserProviderTests {
    private let account = Account(id: 548, username: "moviefan", name: "Movie Fan", avatarPath: nil)

    @Test
    func signedOutMapsToNil() async throws {
        // Given
        let sut: any CurrentUserProvider = makeSUT(states: [.signedOut])

        // When
        let accountID = try #require(await sut.accountIDs.first { _ in true })

        // Assert
        #expect(accountID == nil)
    }

    @Test
    func signedInMapsToAccountID() async throws {
        // Given
        let sut: any CurrentUserProvider = makeSUT(states: [.signedIn(account)])

        // When
        let accountID = try #require(await sut.accountIDs.first { _ in true })

        // Assert
        #expect(accountID == 548)
    }

    @Test
    func refreshedAccountYieldsOnce() async {
        // Given
        let renamed = Account(id: 548, username: "moviefan", name: "Renamed Fan", avatarPath: nil)
        let sut: any CurrentUserProvider = makeSUT(states: [.signedIn(account), .signedIn(renamed)])
        var accountIDs: [Account.ID?] = []

        // When
        for await accountID in await sut.accountIDs {
            accountIDs.append(accountID)
        }

        // Assert
        #expect(accountIDs == [548])
    }
}

private extension AuthCurrentUserProviderTests {
    func makeSUT(states: [AuthState]) -> AuthCurrentUserProvider {
        AuthCurrentUserProvider(authRepository: AuthRepositoryStub(states: states))
    }
}
