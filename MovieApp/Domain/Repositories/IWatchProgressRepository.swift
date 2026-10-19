nonisolated protocol IWatchProgressRepository: Sendable {
    // Each subscriber gets the current state first (records most recent first), then every change. While signed out,
    // reads are empty and writes do nothing.
    var changes: AsyncStream<AccountScoped<[WatchProgress]>> { get async }

    func upsert(_ progress: WatchProgress) async throws
    func progress(for contentID: Int, mediaType: MediaType) async throws -> WatchProgress?
    func recent(limit: Int) async throws -> [WatchProgress]
    func removeAll() async throws
}
