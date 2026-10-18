nonisolated protocol IAuthRepository: Sendable {
    var changes: AsyncStream<AuthState> { get async }

    func signIn() async throws -> Account
    func signOut() async
    func refreshAccount() async -> AccountRefreshResult
}
