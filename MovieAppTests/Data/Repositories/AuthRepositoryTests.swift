import Foundation
@testable import MovieApp
import Testing

struct AuthRepositoryTests {
    private let authSession = AuthSession(
        accessToken: "access-token",
        accountObjectID: "4bc889",
        sessionID: "session",
        accountID: 548,
        username: "moviefan",
        name: "Movie Fan",
        avatarPath: nil
    )
    private let account = Account(id: 548, username: "moviefan", name: "Movie Fan", avatarPath: nil)

    @Test
    func changesStartsSignedInWhenKeychainHasCredentials() async throws {
        // Given
        let sut = makeSUT(keychain: try makeKeychainHoldingCredentials())

        // When
        let changes = await sut.changes

        // Assert
        #expect(await changes.first { _ in true } == .signedIn(account))
    }

    @Test
    func changesStartsSignedOutWhenStoredSessionIsUnreadable() async {
        // Given
        let sut = makeSUT(keychain: KeychainServiceStub(items: ["tmdb-session": Data("not json".utf8)]))

        // When
        let changes = await sut.changes

        // Assert
        #expect(await changes.first { _ in true } == .signedOut)
    }

    @Test
    func changesStartsSignedOutWhenKeychainIsEmpty() async {
        // Given
        let sut = makeSUT()

        // When
        let changes = await sut.changes

        // Assert
        #expect(await changes.first { _ in true } == .signedOut)
    }

    @Test
    func signInReturnsAccount() async throws {
        // Given
        let sut = makeSUT(sessionService: SessionServiceStub(result: .success(authSession)))

        // When
        let signedInAccount = try await sut.signIn()

        // Assert
        #expect(signedInAccount == account)
    }

    @Test
    func signInBroadcastsSignedIn() async throws {
        // Given
        let sut = makeSUT(sessionService: SessionServiceStub(result: .success(authSession)))
        let changes = await sut.changes

        // When
        _ = try await sut.signIn()

        // Assert
        #expect(await changes.first { _ in true } == .signedIn(account))
    }

    @Test
    func signInSavesTheCredentials() async throws {
        // Given
        let keychain = KeychainServiceStub()
        let sut = makeSUT(keychain: keychain, sessionService: SessionServiceStub(result: .success(authSession)))

        // When
        _ = try await sut.signIn()

        // Assert
        #expect(keychain.storedKeys == ["tmdb-session"])
    }

    @Test
    func failedSaveLeavesSignedOut() async {
        // Given
        let sut = makeSUT(
            keychain: KeychainServiceStub(setData: .failure(StubError.failed)),
            sessionService: SessionServiceStub(result: .success(authSession))
        )

        // When
        _ = try? await sut.signIn()

        // Assert
        #expect(await sut.changes.first { _ in true } == .signedOut)
    }

    @Test
    func failedSessionStoresNothing() async {
        // Given
        let keychain = KeychainServiceStub()
        let sut = makeSUT(keychain: keychain, sessionService: SessionServiceStub(result: .failure(StubError.failed)))

        // When
        _ = try? await sut.signIn()

        // Assert
        #expect(keychain.storedKeys.isEmpty)
    }

    @Test
    func cancelledSessionStoresNothing() async {
        // Given
        let keychain = KeychainServiceStub()
        let sut = makeSUT(keychain: keychain, sessionService: SessionServiceStub(result: .failure(CancellationError())))

        // When
        _ = try? await sut.signIn()

        // Assert
        #expect(keychain.storedKeys.isEmpty)
    }

    @Test
    func concurrentSignInsCreateOneSession() async throws {
        // Given
        let sessionService = SessionServiceStub(result: .success(authSession), isReleased: false)
        let sut = makeSUT(sessionService: sessionService)

        // When
        let firstSignIn = Task { try await sut.signIn() }
        await sessionService.waitForCreateSession()
        let secondSignIn = Task { try await sut.signIn() }
        _ = await sut.changes
        await sessionService.release()
        _ = try await (firstSignIn.value, secondSignIn.value)

        // Assert
        #expect(await sessionService.createSessionCount == 1)
    }

    @Test
    func signInWhileSignedInSkipsService() async throws {
        // Given
        let sessionService = SessionServiceStub(result: .success(authSession))
        let sut = makeSUT(keychain: try makeKeychainHoldingCredentials(), sessionService: sessionService)

        // When
        _ = try await sut.signIn()

        // Assert
        #expect(await sessionService.createSessionCount == 0)
    }

    @Test
    func signOutRemovesTheCredentials() async throws {
        // Given
        let keychain = try makeKeychainHoldingCredentials()
        let sut = makeSUT(keychain: keychain)

        // When
        await sut.signOut()

        // Assert
        #expect(keychain.storedKeys.isEmpty)
    }

    @Test
    func signOutBroadcastsSignedOut() async throws {
        // Given
        let sut = makeSUT(keychain: try makeKeychainHoldingCredentials())
        let changes = await sut.changes

        // When
        await sut.signOut()

        // Assert
        #expect(await changes.first { _ in true } == .signedOut)
    }

    @Test
    func signOutRevokesStoredSession() async throws {
        // Given
        let sessionService = SessionServiceStub(result: .success(authSession))
        let sut = makeSUT(keychain: try makeKeychainHoldingCredentials(), sessionService: sessionService)

        // When
        await sut.signOut()

        // Assert
        #expect(await sessionService.revokedSessions == [authSession])
    }

    @Test
    func failedDeleteKeepsSignedIn() async throws {
        // Given
        let sut = makeSUT(keychain: try makeKeychainHoldingCredentials(removeData: .failure(StubError.failed)))

        // When
        await sut.signOut()

        // Assert
        #expect(await sut.changes.first { _ in true } == .signedIn(account))
    }

    @Test
    func failedDeleteRevokesNothing() async throws {
        // Given
        let sessionService = SessionServiceStub(result: .success(authSession))
        let sut = makeSUT(
            keychain: try makeKeychainHoldingCredentials(removeData: .failure(StubError.failed)),
            sessionService: sessionService
        )

        // When
        await sut.signOut()

        // Assert
        #expect(await sessionService.revokedSessions.isEmpty)
    }

    @Test
    func signOutDuringSignInDoesNothing() async throws {
        // Given
        let sessionService = SessionServiceStub(result: .success(authSession), isReleased: false)
        let sut = makeSUT(sessionService: sessionService)
        let signIn = Task { try await sut.signIn() }
        await sessionService.waitForCreateSession()

        // When
        await sut.signOut()

        // Assert
        #expect(await sessionService.revokedSessions.isEmpty)
        await sessionService.release()
        _ = try await signIn.value
    }

    @Test
    func signOutWhenSignedOutDoesNothing() async {
        // Given
        let sessionService = SessionServiceStub(result: .success(authSession))
        let sut = makeSUT(sessionService: sessionService)

        // When
        await sut.signOut()

        // Assert
        #expect(await sessionService.revokedSessions.isEmpty)
    }
}

private extension AuthRepositoryTests {
    func makeSUT(
        keychain: KeychainServiceStub = KeychainServiceStub(),
        sessionService: SessionServiceStub = SessionServiceStub(result: .failure(StubError.failed))
    ) -> any IAuthRepository {
        AuthRepository(sessionService: sessionService, credentialRepository: CredentialRepository(keychain: keychain))
    }

    func makeKeychainHoldingCredentials(
        removeData: Result<Void, any Error> = .success(())
    ) throws -> KeychainServiceStub {
        KeychainServiceStub(items: ["tmdb-session": try JSONEncoder().encode(authSession)], removeData: removeData)
    }
}
