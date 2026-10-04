@testable import MovieApp
import UIKit

@MainActor
final class SceneFactorySpy {
    let home = UIViewController()
    let search = UIViewController()
    let genreMovies = UIViewController()
    let saved = UIViewController()
    let profile = UIViewController()
    private(set) var homeSelectionHandler: ((Movie) -> Void)?
    private(set) var searchSelectionHandler: ((Genre) -> Void)?
    private(set) var genreMoviesSelectionHandler: ((Movie) -> Void)?
    private(set) var savedSelectionHandler: ((Movie) -> Void)?
    private(set) var genreMoviesRequests: [Genre] = []
    private(set) var movieDetailRequests: [Movie] = []
}

// MARK: - HomeFactory
extension SceneFactorySpy: HomeFactory {
    func makeHome(onSelectMovie: @escaping (Movie) -> Void) -> UIViewController {
        homeSelectionHandler = onSelectMovie
        return home
    }
}

// MARK: - SearchFactory
extension SceneFactorySpy: SearchFactory {
    func makeSearch(onSelectGenre: @escaping (Genre) -> Void) -> UIViewController {
        searchSelectionHandler = onSelectGenre
        return search
    }
}

// MARK: - GenreMoviesFactory
extension SceneFactorySpy: GenreMoviesFactory {
    func makeGenreMovies(genre: Genre, onSelectMovie: @escaping (Movie) -> Void) -> UIViewController {
        genreMoviesRequests.append(genre)
        genreMoviesSelectionHandler = onSelectMovie
        return genreMovies
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
