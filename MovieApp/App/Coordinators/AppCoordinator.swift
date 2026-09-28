import UIKit

final class AppCoordinator {
    typealias Dependencies = MainTabCoordinator.Dependencies

    private let window: UIWindow
    private let dependencies: any Dependencies
    private var mainTabCoordinator: MainTabCoordinator?

    init(window: UIWindow, dependencies: any Dependencies) {
        self.window = window
        self.dependencies = dependencies
    }
}

// MARK: - Coordinator
extension AppCoordinator: Coordinator {
    func start() {
        let coordinator = MainTabCoordinator(dependencies: dependencies)
        coordinator.start()
        mainTabCoordinator = coordinator
        window.tintColor = .brand
        window.rootViewController = coordinator.tabBarController
        window.makeKeyAndVisible()
    }
}
