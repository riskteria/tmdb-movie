import MovieAppDS
import UIKit

protocol ProfileFactory {
    func makeProfile(
        onRequestSignOut: @escaping (ProfileModel.DisplayedConfirmation, @escaping () -> Void) -> Void
    ) -> UIViewController
}

final class ProfileCoordinator {
    typealias Dependencies = ProfileFactory

    let navigationController = UINavigationController()
    private let dependencies: any Dependencies

    init(dependencies: any Dependencies) {
        self.dependencies = dependencies
    }

    func makeSignOutAlert(
        for confirmation: ProfileModel.DisplayedConfirmation,
        onConfirm: @escaping () -> Void
    ) -> UIAlertController {
        let alert = UIAlertController(title: confirmation.title, message: confirmation.message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: confirmation.cancelTitle, style: .cancel))
        alert.addAction(UIAlertAction(title: confirmation.confirmTitle, style: .destructive) { _ in onConfirm() })
        return alert
    }
}

// MARK: - Coordinator
extension ProfileCoordinator: Coordinator {
    func start() {
        NavigationBarStyle.apply(to: navigationController.navigationBar, prefersLargeTitles: true)
        let profile = dependencies.makeProfile { [weak self] confirmation, onConfirm in
            self?.confirmSignOut(confirmation, onConfirm: onConfirm)
        }
        navigationController.setViewControllers([profile], animated: false)
    }
}

private extension ProfileCoordinator {
    func confirmSignOut(_ confirmation: ProfileModel.DisplayedConfirmation, onConfirm: @escaping () -> Void) {
        navigationController.present(makeSignOutAlert(for: confirmation, onConfirm: onConfirm), animated: true)
    }
}
