import Foundation

actor AuthRepository {
    private nonisolated enum Phase {
        case signedOut
        case signInPending(Task<AuthSession, any Error>)
        case signedIn(AuthSession)
    }

    private let sessionService: any ISessionService
    private let credentialRepository: CredentialRepository
    private let broadcaster = AsyncBroadcaster<AuthState>()
    private var phase: Phase

    private var state: AuthState {
        switch phase {
        case .signedOut, .signInPending:
            .signedOut
        case .signedIn(let authSession):
            .signedIn(makeAccount(from: authSession))
        }
    }

    init(sessionService: any ISessionService, credentialRepository: CredentialRepository) {
        self.sessionService = sessionService
        self.credentialRepository = credentialRepository
        if let authSession = try? credentialRepository.load() {
            phase = .signedIn(authSession)
        } else {
            phase = .signedOut
        }
    }

    private func transition(to newPhase: Phase) async {
        phase = newPhase
        await broadcaster.send(state)
    }
}

// MARK: - IAuthRepository
extension AuthRepository: IAuthRepository {
    var changes: AsyncStream<AuthState> {
        get async {
            await broadcaster.subscribe(startingWith: state)
        }
    }

    func signIn() async throws -> Account {
        switch phase {
        case .signedIn(let authSession):
            return makeAccount(from: authSession)
        case .signInPending(let task):
            return try await makeAccount(from: task.value)
        case .signedOut:
            let task = Task { try await completeSignIn() }
            phase = .signInPending(task)
            return try await makeAccount(from: task.value)
        }
    }

    func signOut() async {
        guard case .signedIn(let authSession) = phase else { return }
        do {
            try credentialRepository.delete()
        } catch {
            return
        }
        await transition(to: .signedOut)
        await sessionService.revokeSession(authSession)
    }

    func refreshAccount() async -> AccountRefreshResult {
        guard case .signedIn(let authSession) = phase else { return .unchanged }
        do {
            let refreshed = try await sessionService.fetchAccount(for: authSession)
            guard isSignedIn(with: authSession) else { return .unchanged }
            try credentialRepository.save(refreshed)
            await transition(to: .signedIn(refreshed))
            return .refreshed
        } catch SessionServiceError.sessionRejected {
            guard isSignedIn(with: authSession) else { return .unchanged }
            return await endRejectedSession()
        } catch {
            return .unchanged
        }
    }
}

private extension AuthRepository {
    func completeSignIn() async throws -> AuthSession {
        do {
            let authSession = try await sessionService.createSession()
            try credentialRepository.save(authSession)
            await transition(to: .signedIn(authSession))
            return authSession
        } catch {
            phase = .signedOut
            throw error
        }
    }

    func endRejectedSession() async -> AccountRefreshResult {
        do {
            try credentialRepository.delete()
        } catch {
            return .unchanged
        }
        await transition(to: .signedOut)
        return .sessionEnded
    }

    func isSignedIn(with authSession: AuthSession) -> Bool {
        guard case .signedIn(let current) = phase else { return false }
        return current.sessionID == authSession.sessionID
    }

    func makeAccount(from authSession: AuthSession) -> Account {
        Account(
            id: authSession.accountID,
            username: authSession.username,
            name: authSession.name,
            avatarPath: authSession.avatarPath.map(ImagePath.init(rawValue:))
        )
    }
}
