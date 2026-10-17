import Foundation

nonisolated struct CredentialRepository {
    private let keychain: any IKeychainService
    private let key = "tmdb-session"

    init(keychain: any IKeychainService) {
        self.keychain = keychain
    }

    func load() throws -> AuthSession? {
        guard let data = try keychain.data(forKey: key) else { return nil }
        return try JSONDecoder().decode(AuthSession.self, from: data)
    }

    func save(_ authSession: AuthSession) throws {
        try keychain.setData(JSONEncoder().encode(authSession), forKey: key)
    }

    func delete() throws {
        try keychain.removeData(forKey: key)
    }
}
