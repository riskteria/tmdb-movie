@testable import MovieApp
import UIKit

@MainActor
final class SceneFactorySpy {
    let home = UIViewController()
    let search = UIViewController()
    let genreMovies = UIViewController()
    let saved = UIViewController()
    let profile = UIViewController()
    let welcome = UIViewController()
    private(set) var homeSelectionHandler: ((Movie) -> Void)?
    private(set) var searchSelectionHandler: ((Genre) -> Void)?
    private(set) var genreMoviesSelectionHandler: ((Movie) -> Void)?
    private(set) var savedSelectionHandler: ((Movie) -> Void)?
    private(set) var profileSignInHandler: ((@escaping () -> Void) -> Void)?
    private(set) var profileSignOutHandler: ((ProfileModel.DisplayedConfirmation, @escaping () -> Void) -> Void)?
    private(set) var welcomeRequestCount = 0
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
    func makeProfile(
        onRequestSignIn: @escaping (@escaping () -> Void) -> Void,
        onRequestSignOut: @escaping (ProfileModel.DisplayedConfirmation, @escaping () -> Void) -> Void
    ) -> UIViewController {
        profileSignInHandler = onRequestSignIn
        profileSignOutHandler = onRequestSignOut
        return profile
    }
}

// MARK: - WelcomeFactory
extension SceneFactorySpy: WelcomeFactory {
    func makeWelcome(
        onSignIn: @escaping () -> Void,
        onContinueAsGuest: @escaping () -> Void
    ) -> UIViewController {
        welcomeRequestCount += 1
        return welcome
    }
}

// MARK: - MovieDetailFactory
extension SceneFactorySpy: MovieDetailFactory {
    func makeMovieDetail(movie: Movie) -> UIViewController {
        movieDetailRequests.append(movie)
        return UIViewController()
    }
}
