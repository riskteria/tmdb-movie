import SwiftData

actor SavedMoviesRepository {
    private let modelContainer: ModelContainer
    private let currentUser: any CurrentUserProvider
    private let evictionPolicy: any ISavedFirstEvictionPolicy
    private lazy var store = SavedMovieStore(modelContainer: modelContainer)
    private var userID: UserID?
    private var savedMovies: [SavedMovie] = []
    private var appliedRevision = 0
    private var broadcaster = AsyncBroadcaster<[SavedMovie]>()
    private var observationTask: Task<Void, Never>?
    private var userIDWaiters: [CheckedContinuation<UserID, Never>] = []

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
    var changes: AsyncStream<[SavedMovie]> {
        get async {
            _ = await activeUserID()
            return broadcaster.subscribe(startingWith: savedMovies)
        }
    }

    func all() async -> [SavedMovie] {
        _ = await activeUserID()
        return savedMovies
    }

    func contains(_ movieID: Movie.ID) async -> Bool {
        _ = await activeUserID()
        return savedMovies.contains { $0.id == movieID }
    }

    func save(_ movie: Movie) async throws {
        let user = await activeUserID()
        let result = try await store.save(movie, for: user, evictionPolicy: evictionPolicy)
        apply(result, for: user)
    }

    func remove(_ movieID: Movie.ID) async throws {
        let user = await activeUserID()
        let result = try await store.remove(movieID, for: user)
        apply(result, for: user)
    }

    func removeAll() async throws {
        let user = await activeUserID()
        let result = try await store.removeAll(for: user)
        apply(result, for: user)
    }
}

private extension SavedMoviesRepository {
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
        let result = try? await store.movies(for: newUserID)
        userID = newUserID
        savedMovies = result?.value ?? []
        appliedRevision = max(appliedRevision, result?.revision ?? 0)
        broadcaster.send(savedMovies)
        let waiters = userIDWaiters
        userIDWaiters = []
        waiters.forEach { waiter in waiter.resume(returning: newUserID) }
    }

    func apply(_ result: StoreResult<[SavedMovie]>, for user: UserID) {
        guard user == userID, result.revision > appliedRevision else { return }
        appliedRevision = result.revision
        savedMovies = result.value
        broadcaster.send(savedMovies)
    }
}
