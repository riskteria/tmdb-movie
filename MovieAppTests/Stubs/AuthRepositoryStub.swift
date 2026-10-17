@testable import MovieApp
import Synchronization

final class AuthRepositoryStub: IAuthRepository {
    enum Call: Equatable {
        case signIn
        case signOut
    }

    private let states: [AuthState]
    private let signInResult: Result<Account, any Error>
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
        signIn: Result<Account, any Error> = .success(Account(id: 548, username: "moviefan", name: "Movie Fan"))
    ) {
        self.states = states
        signInResult = signIn
    }

    func signIn() async throws -> Account {
        recordedCalls.withLock { $0.append(.signIn) }
        return try signInResult.get()
    }

    func signOut() async {
        recordedCalls.withLock { $0.append(.signOut) }
    }
}
