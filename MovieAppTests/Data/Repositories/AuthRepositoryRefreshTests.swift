import Foundation
@testable import MovieApp
import Testing

struct AuthRepositoryRefreshTests {
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
    private let refreshedSession = AuthSession(
        accessToken: "access-token",
        accountObjectID: "4bc889",
        sessionID: "session",
        accountID: 548,
        username: "moviefan",
        name: "Movie Buff",
        avatarPath: "/avatar.jpg"
    )
    private let refreshedAccount = Account(
        id: 548,
        username: "moviefan",
        name: "Movie Buff",
        avatarPath: ImagePath(rawValue: "/avatar.jpg")
    )

    @Test
    func refreshAccountWhenSignedOutSendsNothing() async {
        // Given
        let sessionService = makeRefreshingSessionService(.success(refreshedSession))
        let sut = makeSUT(sessionService: sessionService)

        // When
        _ = await sut.refreshAccount()

        // Assert
        #expect(await sessionService.fetchAccountCount == 0)
    }

    @Test
    func refreshAccountSavesUpdatedSession() async throws {
        // Given
        let keychain = try makeKeychainHoldingCredentials()
        let sut = makeSUT(keychain: keychain, sessionService: makeRefreshingSessionService(.success(refreshedSession)))

        // When
        _ = await sut.refreshAccount()

        // Assert
        #expect(try CredentialRepository(keychain: keychain).load() == refreshedSession)
    }

    @Test
    func refreshAccountBroadcastsUpdatedAccount() async throws {
        // Given
        let sut = makeSUT(
            keychain: try makeKeychainHoldingCredentials(),
            sessionService: makeRefreshingSessionService(.success(refreshedSession))
        )
        let changes = await sut.changes

        // When
        _ = await sut.refreshAccount()

        // Assert
        #expect(await changes.first { _ in true } == .signedIn(refreshedAccount))
    }

    @Test
    func failedRefreshKeepsAccount() async throws {
        // Given
        let sut = makeSUT(
            keychain: try makeKeychainHoldingCredentials(),
            sessionService: makeRefreshingSessionService(.failure(StubError.failed))
        )

        // When
        _ = await sut.refreshAccount()

        // Assert
        #expect(await sut.changes.first { _ in true } == .signedIn(account))
    }

    @Test
    func failedSaveKeepsPreviousAccount() async throws {
        // Given
        let sut = makeSUT(
            keychain: try makeKeychainHoldingCredentials(setData: .failure(StubError.failed)),
            sessionService: makeRefreshingSessionService(.success(refreshedSession))
        )

        // When
        _ = await sut.refreshAccount()

        // Assert
        #expect(await sut.changes.first { _ in true } == .signedIn(account))
    }

    @Test
    func signOutDuringRefreshSavesNothing() async throws {
        // Given
        let keychain = try makeKeychainHoldingCredentials()
        let sessionService = SessionServiceStub(
            result: .failure(StubError.failed),
            fetchAccount: .success(refreshedSession),
            isReleased: false
        )
        let sut = makeSUT(keychain: keychain, sessionService: sessionService)
        let refresh = Task { await sut.refreshAccount() }
        await sessionService.waitForFetchAccount()

        // When
        await sut.signOut()
        await sessionService.release()
        _ = await refresh.value

        // Assert
        #expect(keychain.storedKeys.isEmpty)
    }

    @Test
    func rejectedSessionReturnsSessionEnded() async throws {
        // Given
        let sut = makeSUT(
            keychain: try makeKeychainHoldingCredentials(),
            sessionService: makeRefreshingSessionService(.failure(SessionServiceError.sessionRejected))
        )

        // When
        let result = await sut.refreshAccount()

        // Assert
        #expect(result == .sessionEnded)
    }

    @Test
    func rejectedSessionBroadcastsSignedOut() async throws {
        // Given
        let sut = makeSUT(
            keychain: try makeKeychainHoldingCredentials(),
            sessionService: makeRefreshingSessionService(.failure(SessionServiceError.sessionRejected))
        )
        let changes = await sut.changes

        // When
        _ = await sut.refreshAccount()

        // Assert
        #expect(await changes.first { _ in true } == .signedOut)
    }

    @Test
    func rejectedSessionRemovesStoredSession() async throws {
        // Given
        let keychain = try makeKeychainHoldingCredentials()
        let sut = makeSUT(
            keychain: keychain,
            sessionService: makeRefreshingSessionService(.failure(SessionServiceError.sessionRejected))
        )

        // When
        _ = await sut.refreshAccount()

        // Assert
        #expect(keychain.storedKeys.isEmpty)
    }

    @Test
    func rejectedSessionRevokesNothing() async throws {
        // Given
        let sessionService = makeRefreshingSessionService(.failure(SessionServiceError.sessionRejected))
        let sut = makeSUT(keychain: try makeKeychainHoldingCredentials(), sessionService: sessionService)

        // When
        _ = await sut.refreshAccount()

        // Assert
        #expect(await sessionService.revokedSessions.isEmpty)
    }

    @Test
    func rejectedSessionStaysSignedInWhenDeleteFails() async throws {
        // Given
        let sut = makeSUT(
            keychain: try makeKeychainHoldingCredentials(removeData: .failure(StubError.failed)),
            sessionService: makeRefreshingSessionService(.failure(SessionServiceError.sessionRejected))
        )

        // When
        _ = await sut.refreshAccount()

        // Assert
        #expect(await sut.changes.first { _ in true } == .signedIn(account))
    }
}

private extension AuthRepositoryRefreshTests {
    func makeSUT(
        keychain: KeychainServiceStub = KeychainServiceStub(),
        sessionService: SessionServiceStub
    ) -> any IAuthRepository {
        AuthRepository(sessionService: sessionService, credentialRepository: CredentialRepository(keychain: keychain))
    }

    func makeKeychainHoldingCredentials(
        setData: Result<Void, any Error> = .success(()),
        removeData: Result<Void, any Error> = .success(())
    ) throws -> KeychainServiceStub {
        KeychainServiceStub(
            items: ["tmdb-session": try JSONEncoder().encode(authSession)],
            setData: setData,
            removeData: removeData
        )
    }

    func makeRefreshingSessionService(_ fetchAccount: Result<AuthSession, any Error>) -> SessionServiceStub {
        SessionServiceStub(result: .failure(StubError.failed), fetchAccount: fetchAccount)
    }
}
