import MovieAppDS
import UIKit

protocol SearchFactory {
    func makeSearch() -> UIViewController
}

final class SearchCoordinator {
    typealias Dependencies = SearchFactory

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
        navigationController.setViewControllers([dependencies.makeSearch()], animated: false)
    }
}
 
