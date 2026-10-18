@testable import MovieApp
import Synchronization

final class AuthRepositoryStub: IAuthRepository {
    enum Call: Equatable {
        case signIn
        case signOut
        case refreshAccount
    }

    private let states: [AuthState]
    private let signInResult: Result<Account, any Error>
    private let refreshAccountResult: AccountRefreshResult
    private let recordedCalls = Mutex<[Call]>([])

    var calls: [Call] {
        recordedCalls.withLock { $0 }
    }

    var changes: AsyncStream<AuthState> {
        get async {
            AsyncStream { continuation in
                states.forEach { state in continuation.yield(state) }
                continuation.finish()
            }
        }
    }

    init(
        states: [AuthState] = [.signedOut],
        signIn: Result<Account, any Error> = .success(
            Account(id: 548, username: "moviefan", name: "Movie Fan", avatarPath: nil)
        ),
        refreshAccount: AccountRefreshResult = .refreshed
    ) {
        self.states = states
        signInResult = signIn
        refreshAccountResult = refreshAccount
    }

    func signIn() async throws -> Account {
        recordedCalls.withLock { $0.append(.signIn) }
        return try signInResult.get()
    }

    func signOut() async {
        recordedCalls.withLock { $0.append(.signOut) }
    }

    func refreshAccount() async -> AccountRefreshResult {
        recordedCalls.withLock { $0.append(.refreshAccount) }
        return refreshAccountResult
    }
}
