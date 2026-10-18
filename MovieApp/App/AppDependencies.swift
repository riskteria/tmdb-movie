import Networking
import Nuke
import SafariServices
import UIKit

final class AppDependencies {
    private static let imageDiskCacheSize = 150 * 1024 * 1024

    private let imageLoader: any IImageLoader
    private let imageURLProvider: any ImageURLProvider = TMDBImageURLProvider()
    private let videoURLProvider: any VideoURLProvider = YouTubeURLProvider()
    private let webURLProvider: any WebURLProvider = TMDBWebURLProvider()
    private let movieRepository: any IMovieRepository
    private let genreRepository: any IGenreRepository
    private let callbackGenreRepository: any ICallbackGenreRepository
    private let authRepository: any IAuthRepository
    private let savedMoviesRepository: any ISavedMoviesRepository
    private let watchProgressRepository: any IWatchProgressRepository
    let appearanceRepository: any IAppearanceRepository = AppearanceRepository()

    init(window: UIWindow) {
        var configuration = ImagePipeline.Configuration.withDataCache(
            name: "com.enkidu.MovieApp.images",
            sizeLimit: Self.imageDiskCacheSize
        )
        configuration.imageCache = ImageCache()
        imageLoader = ImageLoader(pipeline: ImagePipeline(configuration: configuration))
        let readAccessToken = AppConfigs.shared.tmdbReadAccessToken
        let credentialRepository = CredentialRepository(
            keychain: KeychainService(service: "com.enkidu.MovieApp.tmdb-session")
        )
        let apiService = APIService(readAccessToken: readAccessToken) {
            try? credentialRepository.load()?.accessToken
        }
        authRepository = AuthRepository(
            sessionService: SessionService(apiService: apiService, webAuthenticator: WebAuthenticator(window: window)),
            credentialRepository: credentialRepository
        )
        let modelContainer = AppModelContainer()
        let currentUser = AuthCurrentUserProvider(
            authRepository: authRepository,
            guestID: GuestIDStore().loadOrCreate()
        )
        savedMoviesRepository = SavedMoviesRepository(
            container: modelContainer,
            currentUser: currentUser,
            evictionPolicy: OldestSavedFirstEvictionPolicy()
        )
        watchProgressRepository = WatchProgressRepository(container: modelContainer, currentUser: currentUser)
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
    func makeProfile(
        onRequestSignIn: @escaping (@escaping () -> Void) -> Void,
        onRequestConfirmation: @escaping (ProfileModel.DisplayedConfirmation, @escaping () -> Void) -> Void,
        onShowAlert: @escaping (ProfileModel.DisplayedAlert) -> Void
    ) -> UIViewController {
        ProfileSceneFactory.make(
            dependencies: ProfileSceneFactory.Dependencies(
                appInfo: Self.makeAppInfo(from: .main),
                appearanceRepository: appearanceRepository,
                authRepository: authRepository,
                savedMoviesRepository: savedMoviesRepository,
                watchProgressRepository: watchProgressRepository,
                imageURLProvider: imageURLProvider,
                imageLoader: imageLoader
            ),
            onRequestSignIn: onRequestSignIn,
            onRequestConfirmation: onRequestConfirmation,
            onShowAlert: onShowAlert
        )
    }
}

// MARK: - WelcomeFactory
extension AppDependencies: WelcomeFactory {
    func makeWelcome(
        onSignIn: @escaping () -> Void,
        onContinueAsGuest: @escaping () -> Void
    ) -> UIViewController {
        WelcomeSceneFactory.make(onSignIn: onSignIn, onContinueAsGuest: onContinueAsGuest)
    }
}

// MARK: - MovieDetailFactory
extension AppDependencies: MovieDetailFactory {
    func makeMovieDetail(
        movie: Movie,
        onSelectMovie: @escaping (Movie) -> Void,
        onWatchTrailer: @escaping (Video) -> Void,
        onShare: @escaping (Movie) -> Void
    ) -> UIViewController {
        MovieDetailSceneFactory.make(
            movie: movie,
            dependencies: MovieDetailSceneFactory.Dependencies(
                movieRepository: movieRepository,
                savedMoviesRepository: savedMoviesRepository,
                watchProgressRepository: watchProgressRepository,
                imageURLProvider: imageURLProvider,
                videoURLProvider: videoURLProvider,
                imageLoader: imageLoader
            ),
            onSelectMovie: onSelectMovie,
            onWatchTrailer: onWatchTrailer,
            onShare: onShare
        )
    }
}

// MARK: - TrailerFactory
extension AppDependencies: TrailerFactory {
    func makeTrailer(video: Video) -> UIViewController? {
        guard let url = videoURLProvider.watchURL(for: video) else { return nil }
        return SFSafariViewController(url: url)
    }
}

// MARK: - ShareFactory
extension AppDependencies: ShareFactory {
    func makeShareSheet(movie: Movie) -> UIViewController? {
        guard let url = webURLProvider.movieURL(for: movie.id) else { return nil }
        return UIActivityViewController(activityItems: [url], applicationActivities: nil)
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
