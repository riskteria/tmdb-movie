import MovieAppDS
import UIKit

final class AppCoordinator {
    typealias Dependencies = MainTabCoordinator.Dependencies

    private let window: UIWindow
    private let dependencies: any Dependencies
    private let appearanceRepository: any IAppearanceRepository
    private var mainTabCoordinator: MainTabCoordinator?
    private var appearanceTask: Task<Void, Never>?

    init(window: UIWindow, dependencies: any Dependencies, appearanceRepository: any IAppearanceRepository) {
        self.window = window
        self.dependencies = dependencies
        self.appearanceRepository = appearanceRepository
    }

    isolated deinit {
        appearanceTask?.cancel()
    }
}

// MARK: - Coordinator
extension AppCoordinator: Coordinator {
    func start() {
        let coordinator = MainTabCoordinator(dependencies: dependencies)
        coordinator.start()
        mainTabCoordinator = coordinator
        window.tintColor = .MVColor(.brand)
        window.rootViewController = coordinator.tabBarController
        observeAppearance()
        window.makeKeyAndVisible()
    }
}

private extension AppCoordinator {
    func observeAppearance() {
        appearanceTask?.cancel()
        appearanceTask = Task { [window, appearanceRepository] in
            for await theme in await appearanceRepository.changes {
                window.overrideUserInterfaceStyle = theme.interfaceStyle
            }
        }
    }
}

private extension AppTheme {
    var interfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .system:
            .unspecified
        case .light:
            .light
        case .dark:
            .dark
        }
    }
}
