import Networking
import Nuke
import UIKit

final class AppDependencies {
    private static let imageDiskCacheSize = 150 * 1024 * 1024

    private let imageLoader: any ImageLoading
    private let imageURLProvider: any ImageURLProvider = TMDBImageURLProvider()
    private let movieRepository: any IMovieRepository
    private let genreRepository: any IGenreRepository
    private let callbackGenreRepository: any ICallbackGenreRepository
    private let savedMoviesRepository: any ISavedMoviesRepository = SavedMoviesRepository()
    private let watchProgressRepository: any IWatchProgressRepository = WatchProgressRepository()
    let appearanceRepository: any IAppearanceRepository = AppearanceRepository()

    init() {
        var configuration = ImagePipeline.Configuration.withDataCache(
            name: "com.enkidu.MovieApp.images",
            sizeLimit: Self.imageDiskCacheSize
        )
        configuration.imageCache = ImageCache()
        imageLoader = NukeImageLoader(pipeline: ImagePipeline(configuration: configuration))
        let readAccessToken = AppConfigs.shared.tmdbReadAccessToken
        let apiService = APIService(readAccessToken: readAccessToken)
        movieRepository = MovieRepository(apiService: apiService)
        genreRepository = GenreRepository(apiService: apiService)
        callbackGenreRepository = CallbackGenreRepository(
            apiService: CallbackAPIService(readAccessToken: readAccessToken)
        )
    }
}

// MARK: - HomeFactory
extension AppDependencies: HomeFactory {
    func makeHome(onSelectMovie: @escaping (Movie) -> Void) -> UIViewController {
        HomeSceneFactory.make(
            dependencies: HomeSceneFactory.Dependencies(
                movieRepository: movieRepository,
                genreRepository: genreRepository,
                watchProgressRepository: watchProgressRepository,
                imageURLProvider: imageURLProvider,
                imageLoader: imageLoader
            ),
            onSelectMovie: onSelectMovie
        )
    }
}

// MARK: - SearchFactory
extension AppDependencies: SearchFactory {
    func makeSearch(onSelectGenre: @escaping (Genre) -> Void) -> UIViewController {
        SearchSceneFactory.make(
            genreRepository: genreRepository,
            callbackGenreRepository: callbackGenreRepository,
            onSelectGenre: onSelectGenre
        )
    }
}

// MARK: - GenreMoviesFactory
extension AppDependencies: GenreMoviesFactory {
    func makeGenreMovies(genre: Genre, onSelectMovie: @escaping (Movie) -> Void) -> UIViewController {
        GenreMoviesSceneFactory.make(
            genre: genre,
            movieRepository: movieRepository,
            imageURLProvider: imageURLProvider,
            imageLoader: imageLoader,
            onSelectMovie: onSelectMovie
        )
    }
}

// MARK: - SavedFactory
extension AppDependencies: SavedFactory {
    func makeSaved(onSelectMovie: @escaping (Movie) -> Void) -> UIViewController {
        SavedSceneFactory.make(
            savedMoviesRepository: savedMoviesRepository,
            imageURLProvider: imageURLProvider,
            imageLoader: imageLoader,
            onSelectMovie: onSelectMovie
        )
    }
}

// MARK: - ProfileFactory
extension AppDependencies: ProfileFactory {
    func makeProfile() -> UIViewController {
        ProfileSceneFactory.make(appInfo: Self.makeAppInfo(from: .main), appearanceRepository: appearanceRepository)
    }
}

// MARK: - MovieDetailFactory
extension AppDependencies: MovieDetailFactory {
    func makeMovieDetail(movie: Movie) -> UIViewController {
        MovieDetailSceneFactory.make(
            movie: movie,
            movieRepository: movieRepository,
            imageURLProvider: imageURLProvider,
            imageLoader: imageLoader
        )
    }
}

private extension AppDependencies {
    static func makeAppInfo(from bundle: Bundle) -> AppInfo {
        AppInfo(
            version: bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "",
            build: bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
        )
    }
}
