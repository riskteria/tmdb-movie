import SwiftData

actor WatchProgressRepository {
    private let modelContainer: ModelContainer
    private let currentUser: any CurrentUserProvider
    private lazy var store = WatchProgressStore(modelContainer: modelContainer)
    private var userID: UserID?
    private var records: [WatchProgress] = []
    private var appliedRevision = 0
    private var broadcaster = AsyncBroadcaster<[WatchProgress]>()
    private var observationTask: Task<Void, Never>?
    private var userIDWaiters: [CheckedContinuation<UserID, Never>] = []

    init(container: AppModelContainer, currentUser: any CurrentUserProvider) {
        modelContainer = container.modelContainer
        self.currentUser = currentUser
    }

    deinit {
        observationTask?.cancel()
    }
}

// MARK: - IWatchProgressRepository
extension WatchProgressRepository: IWatchProgressRepository {
    var changes: AsyncStream<[WatchProgress]> {
        get async {
            _ = await activeUserID()
            return broadcaster.subscribe(startingWith: records)
        }
    }

    func upsert(_ progress: WatchProgress) async throws {
        let user = await activeUserID()
        let result = try await store.upsert(progress, for: user)
        apply(result, for: user)
    }

    func progress(for contentID: Int, mediaType: MediaType) async -> WatchProgress? {
        _ = await activeUserID()
        return records.first { $0.contentID == contentID && $0.mediaType == mediaType }
    }

    func recent(limit: Int) async -> [WatchProgress] {
        _ = await activeUserID()
        return Array(records.prefix(limit))
    }

    func removeAll() async throws {
        let user = await activeUserID()
        let result = try await store.removeAll(for: user)
        apply(result, for: user)
    }
}

private extension WatchProgressRepository {
    func activeUserID() async -> UserID {
        if let userID {
            return userID
        }
        startObservingCurrentUser()
        return await withCheckedContinuation { continuation in
            userIDWaiters.append(continuation)
        }
    }

    func startObservingCurrentUser() {
        guard observationTask == nil else { return }
        observationTask = Task { [weak self, currentUser] in
            for await userID in await currentUser.userIDs {
                await self?.switchUser(to: userID)
            }
        }
    }

    func switchUser(to newUserID: UserID) async {
        guard newUserID != userID else { return }
        let result = try? await store.records(for: newUserID)
        userID = newUserID
        records = result?.value ?? []
        appliedRevision = max(appliedRevision, result?.revision ?? 0)
        broadcaster.send(records)
        let waiters = userIDWaiters
        userIDWaiters = []
        waiters.forEach { waiter in waiter.resume(returning: newUserID) }
    }

    func apply(_ result: StoreResult<[WatchProgress]>, for user: UserID) {
        guard user == userID, result.revision > appliedRevision else { return }
        appliedRevision = result.revision
        records = result.value
        broadcaster.send(records)
    }
}
