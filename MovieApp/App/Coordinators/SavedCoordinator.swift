import UIKit

protocol SavedFactory {
    func makeSaved(onSelectMovie: @escaping (Movie) -> Void) -> UIViewController
}

final class SavedCoordinator {
    typealias Dependencies = SavedFactory & MovieDetailFactory

    let navigationController = UINavigationController()
    private let dependencies: any Dependencies
    private lazy var movieDetailFlow = MovieDetailFlow(
        navigationController: navigationController,
        dependencies: dependencies
    )

    init(dependencies: any Dependencies) {
        self.dependencies = dependencies
    }
}

// MARK: - Coordinator
extension SavedCoordinator: Coordinator {
    func start() {
        NavigationBarStyle.apply(to: navigationController.navigationBar, prefersLargeTitles: true)
        let saved = dependencies.makeSaved { [weak self] movie in
            self?.movieDetailFlow.showDetail(for: movie, transition: .push)
        }
        navigationController.setViewControllers([saved], animated: false)
    }
}
