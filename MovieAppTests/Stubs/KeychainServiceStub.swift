import Foundation
@testable import MovieApp
import Synchronization

final class KeychainServiceStub: IKeychainService {
    private let items: Mutex<[String: Data]>
    private let setDataResult: Result<Void, any Error>
    private let removeDataResult: Result<Void, any Error>

    var storedKeys: [String] {
        items.withLock { $0.keys.sorted() }
    }

    init(
        items: [String: Data] = [:],
        setData: Result<Void, any Error> = .success(()),
        removeData: Result<Void, any Error> = .success(())
    ) {
        self.items = Mutex(items)
        setDataResult = setData
        removeDataResult = removeData
    }

    func data(forKey key: String) throws -> Data? {
        items.withLock { $0[key] }
    }

    func setData(_ data: Data, forKey key: String) throws {
        try setDataResult.get()
        items.withLock { $0[key] = data }
    }

    func removeData(forKey key: String) throws {
        try removeDataResult.get()
        items.withLock { $0[key] = nil }
    }
}
