import UIKit

protocol ProfileFactory {
    func makeProfile() -> UIViewController
}

// Week 4 adds the confirmation alerts for the clear actions.
final class ProfileCoordinator {
    typealias Dependencies = ProfileFactory

    let navigationController = UINavigationController()
    private let dependencies: any Dependencies

    init(dependencies: any Dependencies) {
        self.dependencies = dependencies
    }
}

// MARK: - Coordinator
extension ProfileCoordinator: Coordinator {
    func start() {
        NavigationBarStyle.apply(to: navigationController.navigationBar, prefersLargeTitles: true)
        navigationController.setViewControllers([dependencies.makeProfile()], animated: false)
    }
}
