@testable import MovieApp

actor SessionServiceStub {
    private let result: Result<AuthSession, any Error>
    private let fetchAccountResult: Result<AuthSession, any Error>
    private var isReleased: Bool
    private var releaseWaiters: [CheckedContinuation<Void, Never>] = []
    private var createSessionWaiters: [CheckedContinuation<Void, Never>] = []
    private var fetchAccountWaiters: [CheckedContinuation<Void, Never>] = []
    private(set) var createSessionCount = 0
    private(set) var fetchAccountCount = 0
    private(set) var revokedSessions: [AuthSession] = []

    init(
        result: Result<AuthSession, any Error>,
        fetchAccount: Result<AuthSession, any Error> = .failure(StubError.failed),
        isReleased: Bool = true
    ) {
        self.result = result
        fetchAccountResult = fetchAccount
        self.isReleased = isReleased
    }

    func waitForCreateSession() async {
        guard createSessionCount == 0 else { return }
        await withCheckedContinuation { createSessionWaiters.append($0) }
    }

    func waitForFetchAccount() async {
        guard fetchAccountCount == 0 else { return }
        await withCheckedContinuation { fetchAccountWaiters.append($0) }
    }

    func release() {
        isReleased = true
        releaseWaiters.forEach { $0.resume() }
        releaseWaiters.removeAll()
    }
}

// MARK: - ISessionService
extension SessionServiceStub: ISessionService {
    func createSession() async throws -> AuthSession {
        createSessionCount += 1
        createSessionWaiters.forEach { $0.resume() }
        createSessionWaiters.removeAll()
        if !isReleased {
            await withCheckedContinuation { releaseWaiters.append($0) }
        }
        return try result.get()
    }

    func fetchAccount(for authSession: AuthSession) async throws -> AuthSession {
        fetchAccountCount += 1
        fetchAccountWaiters.forEach { $0.resume() }
        fetchAccountWaiters.removeAll()
        if !isReleased {
            await withCheckedContinuation { releaseWaiters.append($0) }
        }
        return try fetchAccountResult.get()
    }

    func revokeSession(_ authSession: AuthSession) async {
        revokedSessions.append(authSession)
    }
}
