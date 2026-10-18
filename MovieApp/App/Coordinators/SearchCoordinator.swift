import MovieAppDS
import UIKit

protocol SearchFactory {
    func makeSearch(onSelectGenre: @escaping (Genre) -> Void) -> UIViewController
}

protocol GenreMoviesFactory {
    func makeGenreMovies(genre: Genre, onSelectMovie: @escaping (Movie) -> Void) -> UIViewController
}

final class SearchCoordinator {
    typealias Dependencies = SearchFactory & GenreMoviesFactory & MovieDetailFlow.Dependencies

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
extension SearchCoordinator: TabCoordinator {
    func start() {
        NavigationBarStyle.apply(to: navigationController.navigationBar, prefersLargeTitles: true)
        let search = dependencies.makeSearch { [weak self] genre in
            self?.showGenreMovies(for: genre)
        }
        navigationController.setViewControllers([search], animated: false)
    }
}

private extension SearchCoordinator {
    func showGenreMovies(for genre: Genre) {
        let genreMovies = dependencies.makeGenreMovies(genre: genre) { [weak self] movie in
            self?.movieDetailFlow.showDetail(for: movie, transition: .push)
        }
        navigationController.pushViewController(genreMovies, animated: true)
    }
}
