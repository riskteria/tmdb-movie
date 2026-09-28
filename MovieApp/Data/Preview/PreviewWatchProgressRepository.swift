import Foundation

// Keeps watch progress in memory. Week 3 adds InMemoryWatchProgressRepository and Week 4 Core Data.
actor PreviewWatchProgressRepository {
    private var records: [WatchProgress]
    private let broadcaster = AsyncBroadcaster<[WatchProgress]>()

    init(records: [WatchProgress] = PreviewCatalog.watchProgress(for: .local(UUID()))) {
        self.records = records.sorted { $0.lastWatchedAt > $1.lastWatchedAt }
    }
}

// MARK: - WatchProgressRepository
extension PreviewWatchProgressRepository: WatchProgressRepository {
    var changes: AsyncStream<[WatchProgress]> {
        get async {
            await broadcaster.subscribe(startingWith: records)
        }
    }

    func upsert(_ progress: WatchProgress) async {
        records.removeAll { $0.contentID == progress.contentID && $0.mediaType == progress.mediaType }
        records.insert(progress, at: 0)
        await broadcaster.send(records)
    }

    func progress(for contentID: Int, mediaType: MediaType) -> WatchProgress? {
        records.first { $0.contentID == contentID && $0.mediaType == mediaType }
    }

    func recent(limit: Int) -> [WatchProgress] {
        Array(records.prefix(limit))
    }

    func removeAll() async {
        records.removeAll()
        await broadcaster.send(records)
    }
}
