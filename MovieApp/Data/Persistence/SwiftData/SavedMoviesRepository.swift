import SwiftData

actor SavedMoviesRepository {
    private let modelContainer: ModelContainer
    private let currentUser: any CurrentUserProvider
    private let evictionPolicy: any ISavedFirstEvictionPolicy
    private lazy var store = SavedMovieStore(modelContainer: modelContainer)
    private var accountID: Account.ID?
    private var hasCurrentUser = false
    private var savedMovies: [SavedMovie] = []
    private var appliedRevision = 0
    private var broadcaster = AsyncBroadcaster<AccountScoped<[SavedMovie]>>()
    private var observationTask: Task<Void, Never>?
    private var currentUserWaiters: [CheckedContinuation<Account.ID?, Never>] = []

    init(
        container: AppModelContainer,
        currentUser: any CurrentUserProvider,
        evictionPolicy: any ISavedFirstEvictionPolicy
    ) {
        modelContainer = container.modelContainer
        self.currentUser = currentUser
        self.evictionPolicy = evictionPolicy
    }

    deinit {
        observationTask?.cancel()
    }
}

// MARK: - ISavedMoviesRepository
extension SavedMoviesRepository: ISavedMoviesRepository {
    var changes: AsyncStream<AccountScoped<[SavedMovie]>> {
        get async {
            _ = await currentAccountID()
            return broadcaster.subscribe(startingWith: currentState)
        }
    }

    func all() async -> [SavedMovie] {
        _ = await currentAccountID()
        return savedMovies
    }

    func contains(_ movieID: Movie.ID) async -> Bool {
        _ = await currentAccountID()
        return savedMovies.contains { $0.id == movieID }
    }

    func save(_ movie: Movie) async throws {
        guard let account = await currentAccountID() else { return }
        let result = try await store.save(movie, for: account, evictionPolicy: evictionPolicy)
        apply(result, for: account)
    }

    func remove(_ movieID: Movie.ID) async throws {
        guard let account = await currentAccountID() else { return }
        let result = try await store.remove(movieID, for: account)
        apply(result, for: account)
    }

    func removeAll() async throws {
        guard let account = await currentAccountID() else { return }
        let result = try await store.removeAll(for: account)
        apply(result, for: account)
    }
}

private extension SavedMoviesRepository {
    var currentState: AccountScoped<[SavedMovie]> {
        accountID == nil ? .signedOut : .signedIn(savedMovies)
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
            let result = try? await store.movies(for: newAccountID)
            savedMovies = result?.value ?? []
            appliedRevision = max(appliedRevision, result?.revision ?? 0)
        } else {
            savedMovies = []
        }
        accountID = newAccountID
        hasCurrentUser = true
        broadcaster.send(currentState)
        let waiters = currentUserWaiters
        currentUserWaiters = []
        waiters.forEach { waiter in waiter.resume(returning: newAccountID) }
    }

    func apply(_ result: StoreResult<[SavedMovie]>, for account: Account.ID) {
        guard account == accountID, result.revision > appliedRevision else { return }
        appliedRevision = result.revision
        savedMovies = result.value
        broadcaster.send(currentState)
    }
}
