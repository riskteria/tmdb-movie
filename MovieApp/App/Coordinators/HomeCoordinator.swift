import MovieAppDS
import UIKit

protocol HomeFactory {
    func makeHome(onSelectMovie: @escaping (Movie) -> Void) -> UIViewController
}

final class HomeCoordinator {
    typealias Dependencies = HomeFactory & MovieDetailFactory

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
extension HomeCoordinator: Coordinator {
    func start() {
        NavigationBarStyle.apply(to: navigationController.navigationBar, prefersLargeTitles: false)
        let home = dependencies.makeHome { [weak self] movie in
            self?.movieDetailFlow.showDetail(for: movie, transition: .zoom)
        }
        navigationController.setViewControllers([home], animated: false)
    }
}
