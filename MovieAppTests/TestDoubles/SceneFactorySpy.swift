@testable import MovieApp
import UIKit

@MainActor
final class SceneFactorySpy {
    let home = UIViewController()
    let discover = UIViewController()
    let saved = UIViewController()
    let profile = UIViewController()
    private(set) var homeSelectionHandler: ((Movie) -> Void)?
    private(set) var savedSelectionHandler: ((Movie) -> Void)?
    private(set) var movieDetailRequests: [Movie] = []
}

// MARK: - HomeFactory
extension SceneFactorySpy: HomeFactory {
    func makeHome(onSelectMovie: @escaping (Movie) -> Void) -> UIViewController {
        homeSelectionHandler = onSelectMovie
        return home
    }
}

// MARK: - DiscoverFactory
extension SceneFactorySpy: DiscoverFactory {
    func makeDiscover() -> UIViewController {
        discover
    }
}

// MARK: - SavedFactory
extension SceneFactorySpy: SavedFactory {
    func makeSaved(onSelectMovie: @escaping (Movie) -> Void) -> UIViewController {
        savedSelectionHandler = onSelectMovie
        return saved
    }
}

// MARK: - ProfileFactory
extension SceneFactorySpy: ProfileFactory {
    func makeProfile() -> UIViewController {
        profile
    }
}

// MARK: - MovieDetailFactory
extension SceneFactorySpy: MovieDetailFactory {
    func makeMovieDetail(movie: Movie) -> UIViewController {
        movieDetailRequests.append(movie)
        return UIViewController()
    }
}
