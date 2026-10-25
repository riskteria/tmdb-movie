import Foundation
@testable import MovieApp
import Synchronization
import Testing

@MainActor
struct HomeInteractorSaveTests {
    private let presenter = HomePresenterSpy()
    private let movie = Movie.fixture(id: 7)

    @Test
    func observeSavedStatePresentsSavedMovieIDs() async {
        // Given
        let states: [AccountScoped<[SavedMovie]>] = [.signedIn([makeSavedMovie(id: 7), makeSavedMovie(id: 9)])]
        let sut = makeSUT(worker: HomeWorkerStub(savedStates: states))

        // When
        await sut.observeSavedState(request: HomeModel.ObserveSavedState.Request())

        // Assert
        #expect(presenter.savedStates == [.signedIn([7, 9])])
    }

    @Test
    func observeSavedStatePresentsSignedOut() async {
        // Given
        let sut = makeSUT(worker: HomeWorkerStub(savedStates: [.signedOut]))

        // When
        await sut.observeSavedState(request: HomeModel.ObserveSavedState.Request())

        // Assert
        #expect(presenter.savedStates == [.signedOut])
    }

    @Test
    func observeSavedStatePresentsOnlyChanges() async {
        // Given
        let states: [AccountScoped<[SavedMovie]>] = [
            .signedIn([]),
            .signedIn([]),
            .signedIn([makeSavedMovie(id: 7)]),
            .signedOut
        ]
        let sut = makeSUT(worker: HomeWorkerStub(savedStates: states))

        // When
        await sut.observeSavedState(request: HomeModel.ObserveSavedState.Request())

        // Assert
        #expect(presenter.savedStates == [.signedIn([]), .signedIn([7]), .signedOut])
    }

    @Test
    func toggleSaveSavesUnsavedMovie() async {
        // Given
        let worker = HomeWorkerStub(savedStates: [.signedIn([])])
        let sut = makeSUT(worker: worker)
        await sut.observeSavedState(request: HomeModel.ObserveSavedState.Request())

        // When
        await sut.toggleSave(request: HomeModel.ToggleSave.Request(movie: movie))

        // Assert
        #expect(worker.calls == [.save(7)])
    }

    @Test
    func toggleSaveRemovesSavedMovie() async {
        // Given
        let worker = HomeWorkerStub(savedStates: [.signedIn([makeSavedMovie(id: 7)])])
        let sut = makeSUT(worker: worker)
        await sut.observeSavedState(request: HomeModel.ObserveSavedState.Request())

        // When
        await sut.toggleSave(request: HomeModel.ToggleSave.Request(movie: movie))

        // Assert
        #expect(worker.calls == [.remove(7)])
    }

    @Test
    func toggleSaveIgnoresTapBeforeStateIsKnown() async {
        // Given
        let worker = HomeWorkerStub()
        let sut = makeSUT(worker: worker)

        // When
        await sut.toggleSave(request: HomeModel.ToggleSave.Request(movie: movie))

        // Assert
        #expect(worker.calls.isEmpty)
    }

    @Test
    func toggleSaveIgnoresTapWhileSignedOut() async {
        // Given
        let worker = HomeWorkerStub(savedStates: [.signedOut])
        let sut = makeSUT(worker: worker)
        await sut.observeSavedState(request: HomeModel.ObserveSavedState.Request())

        // When
        await sut.toggleSave(request: HomeModel.ToggleSave.Request(movie: movie))

        // Assert
        #expect(worker.calls.isEmpty)
    }

    @Test
    func toggleSavePresentsSaveFailure() async throws {
        // Given
        let sut = makeSUT(worker: HomeWorkerStub(savedStates: [.signedIn([])], save: .failure(StubError.failed)))
        await sut.observeSavedState(request: HomeModel.ObserveSavedState.Request())

        // When
        await sut.toggleSave(request: HomeModel.ToggleSave.Request(movie: movie))

        // Assert
        let response = try #require(presenter.toggleSaveResponses.first)
        #expect(response.action == .save)
        #expect(response.movie == movie)
    }

    @Test
    func toggleSavePresentsRemoveFailure() async throws {
        // Given
        let worker = HomeWorkerStub(
            savedStates: [.signedIn([makeSavedMovie(id: 7)])],
            remove: .failure(StubError.failed)
        )
        let sut = makeSUT(worker: worker)
        await sut.observeSavedState(request: HomeModel.ObserveSavedState.Request())

        // When
        await sut.toggleSave(request: HomeModel.ToggleSave.Request(movie: movie))

        // Assert
        let response = try #require(presenter.toggleSaveResponses.first)
        #expect(response.action == .remove)
        #expect(response.movie == movie)
    }

    @Test
    func toggleSaveIgnoresCancellation() async {
        // Given
        let sut = makeSUT(worker: HomeWorkerStub(savedStates: [.signedIn([])], save: .failure(CancellationError())))
        await sut.observeSavedState(request: HomeModel.ObserveSavedState.Request())

        // When
        await sut.toggleSave(request: HomeModel.ToggleSave.Request(movie: movie))

        // Assert
        #expect(presenter.toggleSaveResponses.isEmpty)
    }

    @Test(.timeLimit(.minutes(1)))
    func toggleSaveIgnoresSecondTapForSameMovieWhileSaving() async {
        // Given
        let worker = SuspendingHomeWorkerStub(suspendedMovieID: movie.id)
        defer { worker.releaseSuspendedSave() }
        let sut = makeSUT(worker: worker)
        await sut.observeSavedState(request: HomeModel.ObserveSavedState.Request())
        Task { await sut.toggleSave(request: HomeModel.ToggleSave.Request(movie: movie)) }
        await worker.waitForSuspendedSave()

        // When
        await sut.toggleSave(request: HomeModel.ToggleSave.Request(movie: movie))

        // Assert
        #expect(worker.savedMovieIDs == [7])
    }

    @Test(.timeLimit(.minutes(1)))
    func toggleSaveAllowsAnotherMovieWhileSaving() async {
        // Given
        let worker = SuspendingHomeWorkerStub(suspendedMovieID: movie.id)
        defer { worker.releaseSuspendedSave() }
        let sut = makeSUT(worker: worker)
        await sut.observeSavedState(request: HomeModel.ObserveSavedState.Request())
        Task { await sut.toggleSave(request: HomeModel.ToggleSave.Request(movie: movie)) }
        await worker.waitForSuspendedSave()

        // When
        await sut.toggleSave(request: HomeModel.ToggleSave.Request(movie: .fixture(id: 9)))

        // Assert
        #expect(worker.savedMovieIDs == [7, 9])
    }

    private func makeSUT(worker: any IHomeWorker) -> any IHomeInteractor {
        HomeInteractor(presenter: presenter, worker: worker)
    }

    private func makeSavedMovie(id: Movie.ID) -> SavedMovie {
        SavedMovie(movie: .fixture(id: id), savedAt: .now)
    }
}

@MainActor
private final class HomePresenterSpy: IHomePresenter {
    private(set) var savedStates: [AccountScoped<Set<Movie.ID>>] = []
    private(set) var toggleSaveResponses: [HomeModel.ToggleSave.Response] = []

    func presentHome(response: HomeModel.LoadHome.Response) {
        Issue.record("Unexpected call to presentHome(response:)")
    }

    func presentSavedState(response: HomeModel.ObserveSavedState.Response) {
        savedStates.append(response.savedState)
    }

    func presentToggleSave(response: HomeModel.ToggleSave.Response) {
        toggleSaveResponses.append(response)
    }
}

private final class HomeWorkerStub: IHomeWorker {
    enum Call: Equatable {
        case save(Movie.ID)
        case remove(Movie.ID)
    }

    private let savedStates: [AccountScoped<[SavedMovie]>]
    private let saveResult: Result<Void, any Error>
    private let removeResult: Result<Void, any Error>
    private let recordedCalls = Mutex<[Call]>([])

    var calls: [Call] {
        recordedCalls.withLock { $0 }
    }

    init(
        savedStates: [AccountScoped<[SavedMovie]>] = [],
        save: Result<Void, any Error> = .success(()),
        remove: Result<Void, any Error> = .success(())
    ) {
        self.savedStates = savedStates
        saveResult = save
        removeResult = remove
    }

    func fetchTrendingMovies(window: TrendingWindow) async throws -> [Movie] {
        Issue.record("Unexpected call to fetchTrendingMovies(window:)")
        return []
    }

    func fetchMovies(in category: MovieCategory, page: Int) async throws -> Page<Movie> {
        Issue.record("Unexpected call to fetchMovies(in:page:)")
        return .fixture([])
    }

    func fetchContinueWatching(limit: Int) async throws -> [ContinueWatchingItem] {
        Issue.record("Unexpected call to fetchContinueWatching(limit:)")
        return []
    }

    func fetchGenres() async throws -> [Genre] {
        Issue.record("Unexpected call to fetchGenres()")
        return []
    }

    func observeWatchProgress() async -> AsyncStream<AccountScoped<[WatchProgress]>> {
        Issue.record("Unexpected call to observeWatchProgress()")
        return AsyncStream { continuation in continuation.finish() }
    }

    func observeSavedMovies() async -> AsyncStream<AccountScoped<[SavedMovie]>> {
        AsyncStream { continuation in
            savedStates.forEach { state in continuation.yield(state) }
            continuation.finish()
        }
    }

    func saveMovie(_ movie: Movie) async throws {
        recordedCalls.withLock { $0.append(.save(movie.id)) }
        try saveResult.get()
    }

    func removeMovie(_ movieID: Movie.ID) async throws {
        recordedCalls.withLock { $0.append(.remove(movieID)) }
        try removeResult.get()
    }
}

private final class SuspendingHomeWorkerStub: IHomeWorker {
    private struct State {
        var savedMovieIDs: [Movie.ID] = []
        var isSaveSuspended = false
        var suspendedSave: CheckedContinuation<Void, Never>?
        var suspensionWaiter: CheckedContinuation<Void, Never>?
    }

    private let suspendedMovieID: Movie.ID
    private let state = Mutex(State())

    var savedMovieIDs: [Movie.ID] {
        state.withLock { $0.savedMovieIDs }
    }

    init(suspendedMovieID: Movie.ID) {
        self.suspendedMovieID = suspendedMovieID
    }

    func waitForSuspendedSave() async {
        await withCheckedContinuation { continuation in
            let isSaveSuspended = state.withLock { state in
                if !state.isSaveSuspended {
                    state.suspensionWaiter = continuation
                }
                return state.isSaveSuspended
            }
            if isSaveSuspended {
                continuation.resume()
            }
        }
    }

    func releaseSuspendedSave() {
        let suspendedSave = state.withLock { state in
            let suspendedSave = state.suspendedSave
            state.suspendedSave = nil
            return suspendedSave
        }
        suspendedSave?.resume()
    }

    func fetchTrendingMovies(window: TrendingWindow) async throws -> [Movie] {
        Issue.record("Unexpected call to fetchTrendingMovies(window:)")
        return []
    }

    func fetchMovies(in category: MovieCategory, page: Int) async throws -> Page<Movie> {
        Issue.record("Unexpected call to fetchMovies(in:page:)")
        return .fixture([])
    }

    func fetchContinueWatching(limit: Int) async throws -> [ContinueWatchingItem] {
        Issue.record("Unexpected call to fetchContinueWatching(limit:)")
        return []
    }

    func fetchGenres() async throws -> [Genre] {
        Issue.record("Unexpected call to fetchGenres()")
        return []
    }

    func observeWatchProgress() async -> AsyncStream<AccountScoped<[WatchProgress]>> {
        Issue.record("Unexpected call to observeWatchProgress()")
        return AsyncStream { continuation in continuation.finish() }
    }

    func observeSavedMovies() async -> AsyncStream<AccountScoped<[SavedMovie]>> {
        AsyncStream { continuation in
            continuation.yield(.signedIn([]))
            continuation.finish()
        }
    }

    func saveMovie(_ movie: Movie) async throws {
        state.withLock { $0.savedMovieIDs.append(movie.id) }
        guard movie.id == suspendedMovieID else { return }
        await withCheckedContinuation { continuation in
            let suspensionWaiter = state.withLock { state in
                state.isSaveSuspended = true
                state.suspendedSave = continuation
                let suspensionWaiter = state.suspensionWaiter
                state.suspensionWaiter = nil
                return suspensionWaiter
            }
            suspensionWaiter?.resume()
        }
    }

    func removeMovie(_ movieID: Movie.ID) async throws {
        Issue.record("Unexpected call to removeMovie(_:)")
    }
}
