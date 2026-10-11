@testable import MovieApp
import Synchronization

final class AppearanceRepositoryStub: IAppearanceRepository {
    private let theme: AppTheme
    private let recordedThemes = Mutex<[AppTheme]>([])

    var savedThemes: [AppTheme] {
        recordedThemes.withLock { $0 }
    }

    var changes: AsyncStream<AppTheme> {
        get async {
            AsyncStream { continuation in
                continuation.yield(theme)
                continuation.finish()
            }
        }
    }

    init(theme: AppTheme = .system) {
        self.theme = theme
    }

    func setTheme(_ theme: AppTheme) async {
        recordedThemes.withLock { $0.append(theme) }
    }
}
