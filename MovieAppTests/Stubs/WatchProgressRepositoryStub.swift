@testable import MovieApp
import Synchronization

final class WatchProgressRepositoryStub: WatchProgressRepository {
    private let records: [WatchProgress]
    private let recordedLimits = Mutex<[Int]>([])

    var requestedLimits: [Int] {
        recordedLimits.withLock { $0 }
    }

    var changes: AsyncStream<[WatchProgress]> {
        get async {
            AsyncStream { continuation in continuation.yield(records) }
        }
    }

    init(records: [WatchProgress]) {
        self.records = records
    }

    func upsert(_ progress: WatchProgress) async throws {}

    func progress(for contentID: Int, mediaType: MediaType) async throws -> WatchProgress? {
        records.first { $0.contentID == contentID && $0.mediaType == mediaType }
    }

    func recent(limit: Int) async throws -> [WatchProgress] {
        recordedLimits.withLock { $0.append(limit) }
        return Array(records.prefix(limit))
    }

    func removeAll() async throws {}
}
