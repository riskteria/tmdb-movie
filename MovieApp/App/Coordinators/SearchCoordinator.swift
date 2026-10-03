import MovieAppDS
import UIKit

protocol DiscoverFactory {
    func makeDiscover() -> UIViewController
}

// Week 2 adds Genre Movies (Discover → MovieGrid → Movie Detail).
final class SearchCoordinator {
    typealias Dependencies = DiscoverFactory

    let navigationController = UINavigationController()
    private let dependencies: any Dependencies

    init(dependencies: any Dependencies) {
        self.dependencies = dependencies
    }
}

// MARK: - Coordinator
extension SearchCoordinator: Coordinator {
    func start() {
        NavigationBarStyle.apply(to: navigationController.navigationBar, prefersLargeTitles: true)
        navigationController.setViewControllers([dependencies.makeDiscover()], animated: false)
    }
}
