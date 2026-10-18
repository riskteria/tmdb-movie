@testable import MovieApp
import Synchronization
import Testing

final class WatchProgressRepositoryStub: IWatchProgressRepository {
    enum Call: Equatable {
        case upsert(WatchProgress)
        case removeAll
    }

    private let result: Result<[WatchProgress], any Error>
    private let upsertResult: Result<Void, any Error>?
    private let removeAllResult: Result<Void, any Error>?
    private let recordedLimits = Mutex<[Int]>([])
    private let recordedCalls = Mutex<[Call]>([])

    var requestedLimits: [Int] {
        recordedLimits.withLock { $0 }
    }

    var calls: [Call] {
        recordedCalls.withLock { $0 }
    }

    var changes: AsyncStream<[WatchProgress]> {
        get async {
            AsyncStream { continuation in
                if case .success(let records) = result {
                    continuation.yield(records)
                }
            }
        }
    }

    init(
        result: Result<[WatchProgress], any Error>,
        upsert: Result<Void, any Error>? = nil,
        removeAll: Result<Void, any Error>? = nil
    ) {
        self.result = result
        upsertResult = upsert
        removeAllResult = removeAll
    }

    func upsert(_ progress: WatchProgress) async throws {
        try record(.upsert(progress), result: upsertResult, unexpected: "upsert(_:)")
    }

    func progress(for contentID: Int, mediaType: MediaType) async throws -> WatchProgress? {
        try result.get().first { $0.contentID == contentID && $0.mediaType == mediaType }
    }

    func recent(limit: Int) async throws -> [WatchProgress] {
        recordedLimits.withLock { $0.append(limit) }
        return try result.get()
    }

    func removeAll() async throws {
        try record(.removeAll, result: removeAllResult, unexpected: "removeAll()")
    }

    private func record(_ call: Call, result: Result<Void, any Error>?, unexpected name: String) throws {
        guard let result else {
            Issue.record("Unexpected call to \(name)")
            return
        }
        recordedCalls.withLock { $0.append(call) }
        try result.get()
    }
}
