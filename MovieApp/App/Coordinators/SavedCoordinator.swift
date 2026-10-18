import MovieAppDS
import UIKit

protocol SavedFactory {
    func makeSaved(onSelectMovie: @escaping (Movie) -> Void) -> UIViewController
}

final class SavedCoordinator {
    typealias Dependencies = SavedFactory & MovieDetailFlow.Dependencies

    let navigationController = UINavigationController()
    private let dependencies: any Dependencies
    private lazy var movieDetailFlow: any MovieDetailNavigator = MovieDetailFlow(
        navigationController: navigationController,
        dependencies: dependencies
    )

    init(dependencies: any Dependencies) {
        self.dependencies = dependencies
    }
}

// MARK: - TabCoordinator
extension SavedCoordinator: TabCoordinator {
    func start() {
        NavigationBarStyle.apply(to: navigationController.navigationBar, prefersLargeTitles: true)
        let saved = dependencies.makeSaved { [weak self] movie in
            self?.movieDetailFlow.showDetail(for: movie, transition: .push)
        }
        navigationController.setViewControllers([saved], animated: false)
    }
}
