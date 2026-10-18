import MovieAppDS
import UIKit

protocol ProfileFactory {
    func makeProfile(
        onRequestSignIn: @escaping (@escaping () -> Void) -> Void,
        onRequestSignOut: @escaping (ProfileModel.DisplayedConfirmation, @escaping () -> Void) -> Void
    ) -> UIViewController
}

protocol WelcomeFactory {
    func makeWelcome(
        onSignIn: @escaping () -> Void,
        onContinueAsGuest: @escaping () -> Void
    ) -> UIViewController
}

final class ProfileCoordinator {
    typealias Dependencies = ProfileFactory & WelcomeFactory

    let navigationController = UINavigationController()
    private let dependencies: any Dependencies
    private var signInTask: Task<Void, Never>?

    init(dependencies: any Dependencies) {
        self.dependencies = dependencies
    }

    isolated deinit {
        signInTask?.cancel()
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
        let profile = dependencies.makeProfile(
            onRequestSignIn: { [weak self] onSignIn in
                self?.showWelcome(onSignIn: onSignIn)
            },
            onRequestSignOut: { [weak self] confirmation, onConfirm in
                self?.confirmSignOut(confirmation, onConfirm: onConfirm)
            }
        )
        navigationController.setViewControllers([profile], animated: false)
    }
}

private extension ProfileCoordinator {
    func showWelcome(onSignIn: @escaping () -> Void) {
        guard navigationController.presentedViewController == nil else { return }
        let welcome = dependencies.makeWelcome(
            onSignIn: { [weak self] in
                self?.dismissWelcomeThenSignIn(onSignIn)
            },
            onContinueAsGuest: { [weak self] in
                self?.navigationController.dismiss(animated: true)
            }
        )
        welcome.modalPresentationStyle = .pageSheet
        welcome.sheetPresentationController?.prefersGrabberVisible = true
        navigationController.present(welcome, animated: true)
    }

    func dismissWelcomeThenSignIn(_ onSignIn: @escaping () -> Void) {
        signInTask?.cancel()
        signInTask = Task { [weak self] in
            await self?.dismissPresentedScreen()
            guard !Task.isCancelled else { return }
            onSignIn()
        }
    }

    func dismissPresentedScreen() async {
        await withCheckedContinuation { continuation in
            navigationController.dismiss(animated: true) {
                continuation.resume()
            }
        }
    }

    func confirmSignOut(_ confirmation: ProfileModel.DisplayedConfirmation, onConfirm: @escaping () -> Void) {
        navigationController.present(makeSignOutAlert(for: confirmation, onConfirm: onConfirm), animated: true)
    }
}
