nonisolated protocol IWatchProgressRepository: Sendable {
    // Each subscriber gets the current records first (most recent first), then every change.
    var changes: AsyncStream<[WatchProgress]> { get async }

    func upsert(_ progress: WatchProgress) async throws
    func progress(for contentID: Int, mediaType: MediaType) async throws -> WatchProgress?
    func recent(limit: Int) async throws -> [WatchProgress]
    func removeAll() async throws
}
