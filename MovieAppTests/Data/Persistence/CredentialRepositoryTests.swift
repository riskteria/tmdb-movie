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
        name: "Movie Fan"
    )

    @Test
    func loadIsNilWhenEmpty() throws {
        // Given
        let sut = CredentialRepository(keychain: KeychainServiceStub())

        // When
        let loaded = try sut.load()

        // Assert
        #expect(loaded == nil)
    }

    @Test
    func saveThenLoadRoundTrips() throws {
        // Given
        let sut = CredentialRepository(keychain: KeychainServiceStub())

        // When
        try sut.save(authSession)

        // Assert
        #expect(try sut.load() == authSession)
    }

    @Test
    func saveWritesUnderSessionKey() throws {
        // Given
        let keychain = KeychainServiceStub()
        let sut = CredentialRepository(keychain: keychain)

        // When
        try sut.save(authSession)

        // Assert
        #expect(keychain.storedKeys == ["tmdb-session"])
    }

    @Test
    func deleteRemovesCredentials() throws {
        // Given
        let keychain = KeychainServiceStub()
        let sut = CredentialRepository(keychain: keychain)
        try sut.save(authSession)

        // When
        try sut.delete()

        // Assert
        #expect(keychain.storedKeys.isEmpty)
    }

    @Test
    func loadThrowsOnInvalidData() {
        // Given
        let sut = CredentialRepository(keychain: KeychainServiceStub(items: ["tmdb-session": Data("not json".utf8)]))

        // When & Assert
        #expect(throws: DecodingError.self) {
            try sut.load()
        }
    }
}
