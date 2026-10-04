import Nuke
import UIKit

final class AppDependencies {
    private static let imageDiskCacheSize = 150 * 1024 * 1024

    private let imageLoader: any ImageLoading
    private let imageURLProvider: any ImageURLProviding = TMDBImageURLProvider()
    private let movieRepository: any IMovieRepository = MovieRepository()
    private let genreRepository: any IGenreRepository
    private let savedMoviesRepository: any ISavedMoviesRepository = SavedMoviesRepository()
    private let watchProgressRepository: any IWatchProgressRepository = WatchProgressRepository()

    init() {
        var configuration = ImagePipeline.Configuration.withDataCache(
            name: "com.enkidu.MovieApp.images",
            sizeLimit: Self.imageDiskCacheSize
        )
        configuration.imageCache = ImageCache()
        imageLoader = NukeImageLoader(pipeline: ImagePipeline(configuration: configuration))
        genreRepository = GenreRepository(apiService: APIService.shared)
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
    func makeSearch() -> UIViewController {
        SearchSceneFactory.make(genreRepository: genreRepository)
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
        ProfileSceneFactory.make(appInfo: Self.makeAppInfo(from: .main))
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
