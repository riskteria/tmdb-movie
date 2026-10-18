import Foundation

actor AppearanceRepository {
    private let themeKey = "appearance.theme"
    private let defaults: UserDefaults
    private var broadcaster = AsyncBroadcaster<AppTheme>()

    init(suiteName: String? = nil) {
        defaults = UserDefaults(suiteName: suiteName) ?? .standard
    }
}

// MARK: - IAppearanceRepository
extension AppearanceRepository: IAppearanceRepository {
    var changes: AsyncStream<AppTheme> {
        broadcaster.subscribe(startingWith: storedTheme())
    }

    func setTheme(_ theme: AppTheme) {
        defaults.set(theme.rawValue, forKey: themeKey)
        broadcaster.send(theme)
    }
}

private extension AppearanceRepository {
    func storedTheme() -> AppTheme {
        defaults.string(forKey: themeKey).flatMap(AppTheme.init(rawValue:)) ?? .system
    }
}
