@testable import MovieApp
import Synchronization
import Testing

final class WatchProgressRepositoryStub: IWatchProgressRepository {
    private let result: Result<[WatchProgress], any Error>
    private let recordedLimits = Mutex<[Int]>([])

    var requestedLimits: [Int] {
        recordedLimits.withLock { $0 }
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

    init(result: Result<[WatchProgress], any Error>) {
        self.result = result
    }

    func upsert(_ progress: WatchProgress) async throws {
        Issue.record("Unexpected call to upsert(_:)")
    }

    func progress(for contentID: Int, mediaType: MediaType) async throws -> WatchProgress? {
        try result.get().first { $0.contentID == contentID && $0.mediaType == mediaType }
    }

    func recent(limit: Int) async throws -> [WatchProgress] {
        recordedLimits.withLock { $0.append(limit) }
        return try result.get()
    }

    func removeAll() async throws {
        Issue.record("Unexpected call to removeAll()")
    }
}
