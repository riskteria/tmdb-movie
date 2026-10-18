import Foundation
@testable import MovieApp
import Testing

struct CredentialRepositoryTests {
    private let authSession = AuthSession(
        accessToken: "access-token",
        accountObjectID: "4bc889",
        sessionID: "session",
        accountID: 548,
        username: "moviefan",
        name: "Movie Fan",
        avatarPath: nil
    )

    @Test
    func loadIsNilWhenEmpty() throws {
        // Given
        let sut: any ICredentialRepository = CredentialRepository(keychain: KeychainServiceStub())

        // When
        let loaded = try sut.load()

        // Assert
        #expect(loaded == nil)
    }

    @Test
    func saveThenLoadRoundTrips() throws {
        // Given
        let sut: any ICredentialRepository = CredentialRepository(keychain: KeychainServiceStub())

        // When
        try sut.save(authSession)

        // Assert
        #expect(try sut.load() == authSession)
    }

    @Test
    func saveWritesUnderSessionKey() throws {
        // Given
        let keychain = KeychainServiceStub()
        let sut: any ICredentialRepository = CredentialRepository(keychain: keychain)

        // When
        try sut.save(authSession)

        // Assert
        #expect(keychain.storedKeys == ["tmdb-session"])
    }

    @Test
    func deleteRemovesCredentials() throws {
        // Given
        let keychain = KeychainServiceStub()
        let sut: any ICredentialRepository = CredentialRepository(keychain: keychain)
        try sut.save(authSession)

        // When
        try sut.delete()

        // Assert
        #expect(keychain.storedKeys.isEmpty)
    }

    @Test
    func loadReadsSessionSavedWithoutAvatarPath() throws {
        // Given
        let previousVersionJSON = """
            {"accessToken":"access-token","accountObjectID":"4bc889","sessionID":"session",\
            "accountID":548,"username":"moviefan","name":"Movie Fan"}
            """
        let keychain = KeychainServiceStub(items: ["tmdb-session": Data(previousVersionJSON.utf8)])
        let sut: any ICredentialRepository = CredentialRepository(keychain: keychain)

        // When
        let loaded = try sut.load()

        // Assert
        #expect(loaded == authSession)
    }

    @Test
    func saveThenLoadKeepsAvatarPath() throws {
        // Given
        let sessionWithAvatar = AuthSession(
            accessToken: "access-token",
            accountObjectID: "4bc889",
            sessionID: "session",
            accountID: 548,
            username: "moviefan",
            name: "Movie Fan",
            avatarPath: "/avatar.jpg"
        )
        let sut: any ICredentialRepository = CredentialRepository(keychain: KeychainServiceStub())

        // When
        try sut.save(sessionWithAvatar)

        // Assert
        #expect(try sut.load() == sessionWithAvatar)
    }

    @Test
    func loadThrowsOnInvalidData() {
        // Given
        let keychain = KeychainServiceStub(items: ["tmdb-session": Data("not json".utf8)])
        let sut: any ICredentialRepository = CredentialRepository(keychain: keychain)

        // When & Assert
        #expect(throws: DecodingError.self) {
            try sut.load()
        }
    }
}
