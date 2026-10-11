import Foundation

actor AppearanceRepository {
    private let themeKey = "appearance.theme"
    private let defaults: UserDefaults
    private let broadcaster = AsyncBroadcaster<AppTheme>()

    init(suiteName: String? = nil) {
        defaults = UserDefaults(suiteName: suiteName) ?? .standard
    }
}

// MARK: - IAppearanceRepository
extension AppearanceRepository: IAppearanceRepository {
    var changes: AsyncStream<AppTheme> {
        get async {
            await broadcaster.subscribe(startingWith: storedTheme())
        }
    }

    func setTheme(_ theme: AppTheme) async {
        defaults.set(theme.rawValue, forKey: themeKey)
        await broadcaster.send(theme)
    }
}

private extension AppearanceRepository {
    func storedTheme() -> AppTheme {
        defaults.string(forKey: themeKey).flatMap(AppTheme.init(rawValue:)) ?? .system
    }
}
