nonisolated protocol IAppearanceRepository: Sendable {
    var changes: AsyncStream<AppTheme> { get async }

    func setTheme(_ theme: AppTheme) async
}
