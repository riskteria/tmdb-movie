import SwiftData

actor WatchProgressRepository {
    private let modelContainer: ModelContainer
    private let currentUser: any CurrentUserProvider
    private lazy var store = WatchProgressStore(modelContainer: modelContainer)
    private var accountID: Account.ID?
    private var hasCurrentUser = false
    private var records: [WatchProgress] = []
    private var appliedRevision = 0
    private var broadcaster = AsyncBroadcaster<AccountScoped<[WatchProgress]>>()
    private var observationTask: Task<Void, Never>?
    private var currentUserWaiters: [CheckedContinuation<Account.ID?, Never>] = []

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
    var changes: AsyncStream<AccountScoped<[WatchProgress]>> {
        get async {
            _ = await currentAccountID()
            return broadcaster.subscribe(startingWith: currentState)
        }
    }

    func upsert(_ progress: WatchProgress) async throws {
        guard let account = await currentAccountID() else { return }
        let result = try await store.upsert(progress, for: account)
        apply(result, for: account)
    }

    func progress(for contentID: Int, mediaType: MediaType) async -> WatchProgress? {
        _ = await currentAccountID()
        return records.first { $0.contentID == contentID && $0.mediaType == mediaType }
    }

    func recent(limit: Int) async -> [WatchProgress] {
        _ = await currentAccountID()
        return Array(records.prefix(limit))
    }

    func removeAll() async throws {
        guard let account = await currentAccountID() else { return }
        let result = try await store.removeAll(for: account)
        apply(result, for: account)
    }
}

private extension WatchProgressRepository {
    var currentState: AccountScoped<[WatchProgress]> {
        accountID == nil ? .signedOut : .signedIn(records)
    }

    func currentAccountID() async -> Account.ID? {
        if hasCurrentUser {
            return accountID
        }
        startObservingCurrentUser()
        return await withCheckedContinuation { continuation in
            currentUserWaiters.append(continuation)
        }
    }

    func startObservingCurrentUser() {
        guard observationTask == nil else { return }
        observationTask = Task { [weak self, currentUser] in
            for await accountID in await currentUser.accountIDs {
                await self?.switchUser(to: accountID)
            }
        }
    }

    func switchUser(to newAccountID: Account.ID?) async {
        guard !hasCurrentUser || newAccountID != accountID else { return }
        if let newAccountID {
            let result = try? await store.records(for: newAccountID)
            records = result?.value ?? []
            appliedRevision = max(appliedRevision, result?.revision ?? 0)
        } else {
            records = []
        }
        accountID = newAccountID
        hasCurrentUser = true
        broadcaster.send(currentState)
        let waiters = currentUserWaiters
        currentUserWaiters = []
        waiters.forEach { waiter in waiter.resume(returning: newAccountID) }
    }

    func apply(_ result: StoreResult<[WatchProgress]>, for account: Account.ID) {
        guard account == accountID, result.revision > appliedRevision else { return }
        appliedRevision = result.revision
        records = result.value
        broadcaster.send(currentState)
    }
}
