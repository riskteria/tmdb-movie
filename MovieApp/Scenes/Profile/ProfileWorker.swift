nonisolated protocol IProfileWorker: Sendable {
    func observeTheme() async -> AsyncStream<AppTheme>
    func saveTheme(_ theme: AppTheme) async
}

nonisolated struct ProfileWorker {
    let appearanceRepository: any IAppearanceRepository
}

// MARK: - IProfileWorker
nonisolated extension ProfileWorker: IProfileWorker {
    func observeTheme() async -> AsyncStream<AppTheme> {
        await appearanceRepository.changes
    }

    func saveTheme(_ theme: AppTheme) async {
        await appearanceRepository.setTheme(theme)
    }
}
