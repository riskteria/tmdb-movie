nonisolated protocol IProfileWorker: Sendable {
    func observeTheme() async -> AsyncStream<AppTheme>
    func saveTheme(_ theme: AppTheme) async
    func observeAuthState() async -> AsyncStream<AuthState>
    func signIn() async throws -> Account
    func signOut() async
    func refreshAccount() async -> AccountRefreshResult
    func clearSavedMovies() async throws
    func clearWatchHistory() async throws
}

nonisolated struct ProfileWorker {
    let appearanceRepository: any IAppearanceRepository
    let authRepository: any IAuthRepository
    let savedMoviesRepository: any ISavedMoviesRepository
    let watchProgressRepository: any IWatchProgressRepository
}

// MARK: - IProfileWorker
nonisolated extension ProfileWorker: IProfileWorker {
    func observeTheme() async -> AsyncStream<AppTheme> {
        await appearanceRepository.changes
    }

    func saveTheme(_ theme: AppTheme) async {
        await appearanceRepository.setTheme(theme)
    }

    func observeAuthState() async -> AsyncStream<AuthState> {
        await authRepository.changes
    }

    func signIn() async throws -> Account {
        try await authRepository.signIn()
    }

    func signOut() async {
        await authRepository.signOut()
    }

    func refreshAccount() async -> AccountRefreshResult {
        await authRepository.refreshAccount()
    }

    func clearSavedMovies() async throws {
        try await savedMoviesRepository.removeAll()
    }

    func clearWatchHistory() async throws {
        try await watchProgressRepository.removeAll()
    }
}
