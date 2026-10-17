import Foundation
import SimpleKeychain

nonisolated protocol IKeychainService: Sendable {
    func data(forKey key: String) throws -> Data?
    func setData(_ data: Data, forKey key: String) throws
    func removeData(forKey key: String) throws
}

nonisolated struct KeychainService {
    private let keychain: SimpleKeychain

    init(service: String) {
        keychain = SimpleKeychain(service: service, accessibility: .afterFirstUnlockThisDeviceOnly)
    }
}

// MARK: - IKeychainService
nonisolated extension KeychainService: IKeychainService {
    func data(forKey key: String) throws -> Data? {
        guard try keychain.hasItem(forKey: key) else { return nil }
        return try keychain.data(forKey: key)
    }

    func setData(_ data: Data, forKey key: String) throws {
        try keychain.set(data, forKey: key)
    }

    func removeData(forKey key: String) throws {
        guard try keychain.hasItem(forKey: key) else { return }
        try keychain.deleteItem(forKey: key)
    }
}
