@testable import MovieApp
import Synchronization

final class ProfileWorkerStub: IProfileWorker {
    enum ClearCall: Equatable {
        case savedMovies
        case watchHistory
    }

    private let themes: AsyncStream<AppTheme>
    private let authStates: AsyncStream<AuthState>
    private let signInResult: Result<Account, any Error>
    private let refreshAccountResult: AccountRefreshResult
    private let refreshGate: AsyncStream<Void>?
    private let recordedThemes = Mutex<[AppTheme]>([])
    private let recordedSignOuts = Mutex(0)
    private let recordedRefreshes = Mutex(0)
    private let clearSavedMoviesResult: Result<Void, any Error>
    private let clearWatchHistoryResult: Result<Void, any Error>
    private let recordedClears = Mutex<[ClearCall]>([])

    var clearCalls: [ClearCall] {
        recordedClears.withLock { $0 }
    }

    var savedThemes: [AppTheme] {
        recordedThemes.withLock { $0 }
    }

    var signOutCount: Int {
        recordedSignOuts.withLock { $0 }
    }

    var refreshAccountCount: Int {
        recordedRefreshes.withLock { $0 }
    }

    init(
        themes: AsyncStream<AppTheme> = AsyncStream { continuation in
            continuation.yield(.system)
            continuation.finish()
        },
        authStates: AsyncStream<AuthState> = AsyncStream { continuation in
            continuation.yield(.signedOut)
            continuation.finish()
        },
        signIn: Result<Account, any Error> = .success(
            Account(id: 548, username: "moviefan", name: "Movie Fan", avatarPath: nil)
        ),
        refreshAccount: AccountRefreshResult = .unchanged,
        refreshGate: AsyncStream<Void>? = nil,
        clearSavedMovies: Result<Void, any Error> = .success(()),
        clearWatchHistory: Result<Void, any Error> = .success(())
    ) {
        self.themes = themes
        self.authStates = authStates
        signInResult = signIn
        refreshAccountResult = refreshAccount
        self.refreshGate = refreshGate
        clearSavedMoviesResult = clearSavedMovies
        clearWatchHistoryResult = clearWatchHistory
    }

    func observeTheme() async -> AsyncStream<AppTheme> {
        themes
    }

    func saveTheme(_ theme: AppTheme) async {
        recordedThemes.withLock { $0.append(theme) }
    }

    func observeAuthState() async -> AsyncStream<AuthState> {
        authStates
    }

    func signIn() async throws -> Account {
        try signInResult.get()
    }

    func signOut() async {
        recordedSignOuts.withLock { $0 += 1 }
    }

    func refreshAccount() async -> AccountRefreshResult {
        recordedRefreshes.withLock { $0 += 1 }
        if let refreshGate {
            for await _ in refreshGate {
                break
            }
        }
        return refreshAccountResult
    }

    func clearSavedMovies() async throws {
        recordedClears.withLock { $0.append(.savedMovies) }
        try clearSavedMoviesResult.get()
    }

    func clearWatchHistory() async throws {
        recordedClears.withLock { $0.append(.watchHistory) }
        try clearWatchHistoryResult.get()
    }
}
