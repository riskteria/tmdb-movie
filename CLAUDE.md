# MovieApp

UIKit movie app built with Clean Architecture and the VIP (Clean Swift) pattern, using Swift Concurrency throughout.

## Quick Reference

- **Platforms**: iOS / iPadOS 26.5+, visionOS 26.5+
- **Toolchain**: Xcode 26.6, Swift 6 language mode (strict concurrency). Both targets enable the upcoming features `ExistentialAny` and `MemberImportVisibility`
- **UI**: UIKit only, layout written in code. No SwiftUI, storyboards or xibs
- **Architecture**: Clean Architecture layers, with VIP inside each scene
- **Concurrency**: async/await, actors and `AsyncStream`. The app target's default isolation is `MainActor`, with Approachable Concurrency on
- **Dependencies**: Swift Package Manager only. Current packages: Alamofire 5 (networking, behind `APIClient`), Nuke 13 (images, behind `ImageLoading`) and `MovieAppDS`, the design system, a local package at `../MovieAppDS`. Ask before adding any other third-party package
- **Secrets**: the TMDB read access token lives in `Config/Secrets.xcconfig`, which is gitignored (copy `Config/Secrets.example.xcconfig`). `Config/App.xcconfig`, the app target's base configuration, includes it, and Info.plist exposes it as `TMDBReadAccessToken`. Never put the token in source
- **Tests**: Swift Testing unit tests only. No UI test target for now
- **Lint**: SwiftLint (`.swiftlint.yml`) runs in a build phase on every build
- **Style**: [Kodeco Swift Style Guide](https://github.com/kodecocodes/swift-style-guide), with 4-space indentation instead of Kodeco's 2

## Commands

**Do not build, test or run the project unless the user explicitly asks.** This covers `xcodebuild build` / `test`, XcodeBuildMCP and iOS Simulator build, test and run tools, and launching the app. Builds and test runs are slow and the user runs them. SwiftLint is not a build: run it freely.

```bash
# Lint / autocorrect (review the diff after --fix)
swiftlint lint --quiet
swiftlint lint --fix --quiet
```

Only when the user asks for a build or test run:

```bash
# Build
xcodebuild -project MovieApp.xcodeproj -scheme MovieApp \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Unit tests (all / one suite / one test)
xcodebuild -project MovieApp.xcodeproj -scheme MovieApp \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test -only-testing:MovieAppTests
  # -only-testing:MovieAppTests/MovieListInteractorTests
  # -only-testing:MovieAppTests/MovieListInteractorTests/loadMoviesPresentsFetchedMovies()
```

When asked to build, run or test, use XcodeBuildMCP or iOS Simulator tools if they are available. Otherwise use `xcodebuild`.

## Definition of Done

A change is complete only when all of these hold:

1. `swiftlint lint --quiet` reports **zero violations**.
2. The code is written to compile with **zero warnings** under Swift 6 strict concurrency. Check types, isolation and imports by reading the code, not by building.
3. New or changed Domain, Data, Worker, Interactor and Presenter code has unit tests.
4. New files sit in the correct layer folder and follow the naming rules below.
5. The final message tells the user which build or test command to run to verify the change. Don't run it yourself.

## Feature Workflow

1. If `docs/specs/<feature>.md` exists, read it first. Use Plan Mode for work that spans several scenes or layers.
2. Implement from the inside out: Domain (entity, repository protocol), then Data (DTO, mapping, repository), then Scene (VIP, with its Worker), then wire it up in `App/`.
3. Write tests for each layer as you go, then lint. Build and run tests only if the user asks.

## Architecture

### Layers and the Dependency Rule

```
Scenes (VIP) ──► Domain ◄── Data
      ▲                      ▲
      └──────── App ─────────┘   (composition root)
```

Dependencies point **inward only**. Domain knows nothing about the other layers.

- **Domain**: entities and repository protocols (ports). Imports `Foundation` only, never `UIKit`. Contains no DTOs, Alamofire, `URLSession` or persistence details.
- **Data**: implements the Domain repository protocols. Holds DTOs, `toDomain()` mapping, networking and persistence. DTOs never leave this layer.
- **Scenes**: the presentation layer, built with VIP. Each scene's Worker reaches data through the Domain ports. Scenes depend only on Domain protocols and entities, never on Data types.
- **App**: `AppDelegate`, `SceneDelegate`, `AppDependencies` and the coordinators in `App/Coordinators/`. This is the only place that knows concrete types from every layer and wires them together, and the only place that pushes or presents view controllers.

SOLID in practice:

- One reason to change per type.
- Small role protocols (`IMovieListInteractor`), not large ones.
- Depend on protocols and inject them through `init`.
- No singletons, no service locators, no global mutable state.

### Project Structure

```
Config/                     App.xcconfig (base configuration), Secrets.example.xcconfig. Secrets.xcconfig is gitignored
MovieApp/
├── App/                    AppDelegate, SceneDelegate, AppDependencies
│   └── Coordinators/       AppCoordinator, MainTabCoordinator, one coordinator per tab, MovieDetailFlow
├── Domain/
│   ├── Entities/           Movie, MovieDetails, Genre, Page, SavedMovie, WatchProgress, …
│   └── Repositories/       MovieRepository, GenreRepository, SavedMoviesRepository, … (protocols)
├── Data/
│   ├── Network/            APIClient (Alamofire), TMDBEndpoint, NetworkError, request interceptors
│   ├── DTOs/               <Name>DTO per endpoint (+ toDomain()), grouped in Movie/, Auth/, Account/, Shared/
│   ├── Observation/        AsyncBroadcaster
│   ├── Persistence/        UserDefaults stores; CoreData/ holds the Core Data stack and repositories
│   ├── Preview/            In-memory sample repositories, used until the remote ones are wired
│   └── Repositories/       RemoteMovieRepository, TMDBImageURLProvider, caching decorators
├── Scenes/
│   └── MovieList/
│       ├── MovieListModels.swift
│       ├── MovieListViewController.swift
│       ├── MovieListInteractor.swift
│       ├── MovieListWorker.swift
│       ├── MovieListPresenter.swift
│       ├── MovieListRouter.swift
│       ├── MovieListSceneFactory.swift
│       └── Views/          Cells, custom UIViews
├── Common/
│   ├── Components/         Shared cells and views (ArtworkView, PosterCell, HeroBannerCell, …)
│   ├── Images/             ImageLoading, NukeImageLoader
│   ├── Transitions/        ZoomTransitionSourceProviding
│   └── Extensions/
├── Resources/              Localizable.xcstrings
├── Assets.xcassets         AccentColor, AppIcon
└── Info.plist
MovieAppTests/              Mirrors MovieApp/, plus TestDoubles/ and Fixtures/
../MovieAppDS/              Design system package: MVFonts, MVColors, Spacing, Radius, ArtworkPalette,
                            NavigationBarStyle, button configurations, the Lexend fonts and the color catalog
```

The project uses Xcode **synchronized folders**. Files created on disk join their target automatically, so **never edit `project.pbxproj` to add files**.

### VIP Scene

```
ViewController ──Request──► Interactor ──Response──► Presenter ──ViewData──► ViewController
      │                          ▲
      │                          │ async
      │                        Worker ──► Domain ports (repositories)
      │
      └──routeTo…(movie:)──► Router ──closure──► Coordinator (App/Coordinators)
```

| Component | Protocol(s) | Responsibility | Never |
|---|---|---|---|
| ViewController | `I<Scene>ViewController` | Builds views, sends user events as a `Request`, renders the `ViewData`, and passes a route's data to the Router | Business logic, formatting, calling the Worker |
| Interactor | `I<Scene>Interactor` | Business rules, scene state, calling its Worker, emitting a `Response` | Importing UIKit, formatting for display, calling repositories directly |
| Worker | `I<Scene>Worker` | The scene's data access: calls the Domain ports and combines their results (for example, merging watch progress with movie details) | Importing UIKit, holding scene state, formatting for display |
| Presenter | `I<Scene>Presenter` | Turns a `Response` into a `ViewData`: localized text, formatted dates and numbers | Importing UIKit, holding state, calling the Worker |
| Router | `I<Scene>Router` | Takes the route's data as a parameter (`routeToMovieDetail(movie:)`) and calls the closures its coordinator passed in through the factory | Depending on the Interactor, touching a navigation controller, building scenes, business logic |
| SceneFactory | none | Builds the scene, including its Worker from the ports it's given, and wires its components | Any other work |
| Models | none | `enum <Scene>Model` namespace, with `Request` / `Response` / `ViewData` for each scene use case | Behavior |

Rules:

- **Ownership**: the ViewController holds the Interactor and Router strongly. The Interactor holds the Presenter and the Worker strongly. The Presenter holds the ViewController `weak`. The Router holds only the coordinator's closures, which capture the coordinator `[weak self]`.
- Inject every dependency through `init` into a `private let`. Never use `var interactor: IMovieListInteractor!`.
- Each scene use case (one `Request` / `Response` / `ViewData` triple) gets one method on each boundary: `loadMovies(request:)` → `presentMovies(response:)` → `displayMovies(viewData:)`. The Worker's methods are named for the data they fetch (`fetchPopularMovies(page:)`).
- Name types `<Scene><Role>`. Put one type per file, with the type's boundary protocol in the same file. The models namespace is `enum <Scene>Model` in `<Scene>Models.swift`, and what the Presenter hands the ViewController is a `ViewData`, passed as `display…(viewData:)`.
- Name each boundary protocol `I` plus the type that implements it: `I<Scene>Interactor`, `I<Scene>Presenter`, `I<Scene>ViewController`, `I<Scene>Worker` and `I<Scene>Router`. The `MARK` above a conformance uses the same name (`// MARK: - IMovieListInteractor`). The `I` prefix is for scene protocols only. Domain ports and other protocols keep role names (`MovieRepository`, `ImageLoading`).
- **Workers are `nonisolated` and `Sendable`**: `nonisolated protocol I<Scene>Worker: Sendable` and `nonisolated struct <Scene>Worker`, with the conformance in a `nonisolated extension`. Interactors call them from child tasks (`async let`), and a nonisolated async method still runs on the Interactor's main actor when called directly. One Worker per scene; two scenes that need the same port each call it, and shared behavior such as caching belongs in a repository decorator.
- Scenes never reach each other. The ViewController passes the data a route needs to its Router as a parameter, and the Router hands it to a coordinator closure (`onSelectMovie(Movie)`); the coordinator builds and shows the next scene. There is no data store, and a Router never depends on the Interactor. This keeps routers free of UIKit and state, and testable with a closure spy.
- **Route data travels in the `ViewData`**: a displayed item the user can open carries the Domain entity its route needs (`let movie: Movie`, with `id` computed from it), so the ViewController can pass it on without asking the Interactor. Tapping, and anything else that only navigates, is not an Interactor use case.

Reference scene (compiles under this project's settings and lint rules):

```swift
enum MovieListModel {
    nonisolated struct DisplayedMovie: Hashable, Sendable {
        let movie: Movie
        let title: String
        let releaseYear: String

        var id: Movie.ID {
            movie.id
        }
    }

    enum LoadMovies {
        struct Request {}

        struct Response {
            let result: Result<[Movie], any Error>
        }

        enum ViewData {
            case content([DisplayedMovie])
            case empty(message: String)
            case failure(message: String)
        }
    }
}
```

```swift
protocol IMovieListInteractor {
    func loadMovies(request: MovieListModel.LoadMovies.Request) async
}

final class MovieListInteractor {
    private let presenter: any IMovieListPresenter
    private let worker: any IMovieListWorker

    init(presenter: any IMovieListPresenter, worker: any IMovieListWorker) {
        self.presenter = presenter
        self.worker = worker
    }
}

// MARK: - IMovieListInteractor
extension MovieListInteractor: IMovieListInteractor {
    func loadMovies(request: MovieListModel.LoadMovies.Request) async {
        do {
            let movies = try await worker.fetchPopularMovies(page: 1)
            presenter.presentMovies(response: MovieListModel.LoadMovies.Response(result: .success(movies)))
        } catch is CancellationError {
            return
        } catch {
            presenter.presentMovies(response: MovieListModel.LoadMovies.Response(result: .failure(error)))
        }
    }
}
```

```swift
nonisolated protocol IMovieListWorker: Sendable {
    func fetchPopularMovies(page: Int) async throws -> [Movie]
}

nonisolated struct MovieListWorker {
    let movieRepository: any MovieRepository
}

// MARK: - IMovieListWorker
nonisolated extension MovieListWorker: IMovieListWorker {
    func fetchPopularMovies(page: Int) async throws -> [Movie] {
        try await movieRepository.popularMovies(page: page)
    }
}
```

```swift
import Foundation

protocol IMovieListPresenter {
    func presentMovies(response: MovieListModel.LoadMovies.Response)
}

final class MovieListPresenter {
    weak var viewController: (any IMovieListViewController)?
}

// MARK: - IMovieListPresenter
extension MovieListPresenter: IMovieListPresenter {
    func presentMovies(response: MovieListModel.LoadMovies.Response) {
        switch response.result {
        case .success(let movies) where movies.isEmpty:
            viewController?.displayMovies(viewData: .empty(message: String(localized: "No movies yet")))
        case .success(let movies):
            viewController?.displayMovies(viewData: .content(movies.map(makeDisplayedMovie(from:))))
        case .failure:
            viewController?.displayMovies(viewData: .failure(message: String(localized: "Unable to load movies")))
        }
    }
}

private extension MovieListPresenter {
    func makeDisplayedMovie(from movie: Movie) -> MovieListModel.DisplayedMovie {
        MovieListModel.DisplayedMovie(
            movie: movie,
            title: movie.title,
            releaseYear: movie.releaseDate?.formatted(.dateTime.year()) ?? "-"
        )
    }
}
```

```swift
import UIKit

protocol IMovieListViewController: AnyObject {
    func displayMovies(viewData: MovieListModel.LoadMovies.ViewData)
}

final class MovieListViewController: UIViewController {
    private let interactor: any IMovieListInteractor
    private let router: any IMovieListRouter
    private var loadTask: Task<Void, Never>?

    private lazy var collectionView = makeCollectionView()
    private lazy var dataSource = makeDataSource()

    init(interactor: any IMovieListInteractor, router: any IMovieListRouter) {
        self.interactor = interactor
        self.router = router
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    isolated deinit {
        loadTask?.cancel()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = String(localized: "Movies")
        setUpLayout()
        loadMovies()
    }

    private func loadMovies() {
        loadTask?.cancel()
        loadTask = Task { [interactor] in
            await interactor.loadMovies(request: MovieListModel.LoadMovies.Request())
        }
    }
}

// MARK: - IMovieListViewController
extension MovieListViewController: IMovieListViewController {
    func displayMovies(viewData: MovieListModel.LoadMovies.ViewData) {
        switch viewData {
        case .content(let movies):
            contentUnavailableConfiguration = nil
            var snapshot = NSDiffableDataSourceSnapshot<Int, MovieListModel.DisplayedMovie>()
            snapshot.appendSections([0])
            snapshot.appendItems(movies)
            dataSource.apply(snapshot)
        case .empty(let message), .failure(let message):
            var configuration = UIContentUnavailableConfiguration.empty()
            configuration.text = message
            contentUnavailableConfiguration = configuration
        }
    }
}

// MARK: - UICollectionViewDelegate
extension MovieListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let movie = dataSource.itemIdentifier(for: indexPath)?.movie else { return }
        router.routeToMovieDetail(movie: movie)
    }
}
```

`setUpLayout()`, `makeCollectionView()` and `makeDataSource()` live in a `private extension MovieListViewController` under `// MARK: - Layout`.

```swift
protocol IMovieListRouter {
    func routeToMovieDetail(movie: Movie)
}

final class MovieListRouter {
    private let onSelectMovie: (Movie) -> Void

    init(onSelectMovie: @escaping (Movie) -> Void) {
        self.onSelectMovie = onSelectMovie
    }
}

// MARK: - IMovieListRouter
extension MovieListRouter: IMovieListRouter {
    func routeToMovieDetail(movie: Movie) {
        onSelectMovie(movie)
    }
}
```

```swift
import UIKit

enum MovieListSceneFactory {
    static func make(
        movieRepository: any MovieRepository,
        onSelectMovie: @escaping (Movie) -> Void
    ) -> UIViewController {
        let worker = MovieListWorker(movieRepository: movieRepository)
        let presenter = MovieListPresenter()
        let interactor = MovieListInteractor(presenter: presenter, worker: worker)
        let router = MovieListRouter(onSelectMovie: onSelectMovie)
        let viewController = MovieListViewController(interactor: interactor, router: router)
        presenter.viewController = viewController
        return viewController
    }
}
```

`AppDependencies` in `App/` owns long-lived services (the Alamofire `Session`, `APIClient`, the Nuke `ImagePipeline`, repositories). It conforms to one `<Scene>Factory` protocol per scene, one extension each, and every `make<Scene>()` calls that scene's `<Scene>SceneFactory`. The two names are different layers: a `<Scene>Factory` protocol (`HomeFactory`) is what a coordinator asks for, and the `<Scene>SceneFactory` enum (`HomeSceneFactory`) wires the VIP components. Coordinators use `AppDependencies` as a factory, but it is one container: every scene shares its instances and the app creates exactly one, so keep the `AppDependencies` name and the `make` prefix. A factory with more than five inputs takes a nested `Dependencies` struct, which keeps it under SwiftLint's parameter limit.

### Coordinators

Coordinators in `App/Coordinators/` own all navigation.

- `AppCoordinator` puts `MainTabCoordinator`'s tab bar controller in the window.
- `MainTabCoordinator` builds three `UITab`s (Home, Saved, Profile) and a `UISearchTab`, whose root is the Discover scene.
- Each tab coordinator owns its `UINavigationController`. It builds scenes and passes the routing closures, capturing itself `[weak self]`.
- **Coordinators never see `AppDependencies`.** Each one declares `typealias Dependencies` as the `<Scene>Factory` protocols it needs (`HomeFactory & MovieDetailFactory`) and stores `any Dependencies`. A protocol lives in the file of the coordinator (or `MovieDetailFlow`) that uses it. A parent's alias combines its children's (`HomeCoordinator.Dependencies & SearchCoordinator.Dependencies & …`). A new scene means a new protocol, a conformance on `AppDependencies`, and a conformance on `SceneFactorySpy`, which stands in for it in coordinator tests.
- `MovieDetailFlow` pushes Movie Detail on its tab's stack. A `.zoom` transition starts from the view the source screen returns through `ZoomTransitionSourceProviding`, and is skipped under Reduce Motion.
- The tab bar stays visible on pushed screens (`hidesBottomBarWhenPushed` stays `false`). Only full-screen modals cover it.

### Images (Nuke)

- Import Nuke only in `Common/Images/` and `App/`.
- `AppDependencies` builds one `ImagePipeline` with its own `ImageCache` and a 150 MB `DataCache`. Never use `ImagePipeline.shared` or `ImageCache.shared`.
- Presenters turn an `ImagePath` into a URL through `ImageURLProviding` and hand cells a `DisplayedArtwork`. `ArtworkView` loads it through `ImageLoading`, downsampled to the view's size, and shows a generated placeholder until then.

### Domain and Data Shape

```swift
nonisolated struct Movie: Identifiable, Hashable, Sendable {
    let id: Int
    let title: String
    let releaseDate: Date?
}

nonisolated protocol MovieRepository: Sendable {
    func popularMovies(page: Int) async throws -> [Movie]
}
```

Domain holds only entities and ports. The code that calls ports for a screen, and combines their results, lives in that scene's Worker (see the reference scene).

### Networking (Alamofire)

`APIClient` wraps Alamofire. Every TMDB endpoint is a case of one enum, `TMDBEndpoint` in `Data/Network/TMDBEndpoint.swift`. Each endpoint's wire types live in one DTO file.

#### Client

- **Confine Alamofire** to `Data/Network/`, `App/` (to build the `Session`) and the Data-layer tests. Repositories use `APIClient`, `TMDBEndpoint`, the DTOs and `NetworkError`. Nothing outside the Data layer sees any of them.
- **One injected `Session`**: `AppDependencies` creates a single `Session` and passes it to `APIClient(session:)`. Never use `AF` or `Session.default`. They are global singletons.
- **Calling an endpoint**: `let page: SearchMoviesDTO.Response = try await apiClient.send(.searchMovies(parameters: .init(query: query)))`, then map the DTO with `toDomain()`.
- **Async API only**: use `serializingDecodable(_:decoder:)` with `.result` or `.value`. Never use the `response…` completion-handler methods. Always call `.validate()` so non-2xx statuses fail.
- **Decoding is already off the main actor**: Alamofire decodes on its serialization queue, so `APIClient` needs no `@concurrent` decode step.
- **Cancellation**: `serializingDecodable` cancels the request when the calling `Task` is cancelled (`automaticallyCancelling` defaults to `true`). It reports this as `AFError.explicitlyCancelled`, so `APIClient` rethrows it as `CancellationError` and the Interactor's `catch is CancellationError` keeps working.
- **Errors**: `AFError` never leaves `APIClient`. Map it to `NetworkError`.

```swift
import Alamofire

nonisolated enum NetworkError: Error, Equatable {
    case invalidResponse(statusCode: Int)
    case decodingFailed
    case requestFailed

    init(_ error: AFError) {
        if let statusCode = error.responseCode {
            self = .invalidResponse(statusCode: statusCode)
        } else if error.isResponseSerializationError {
            self = .decodingFailed
        } else {
            self = .requestFailed
        }
    }
}
```

```swift
import Alamofire
import Foundation

nonisolated final class APIClient: Sendable {
    private let session: Session
    private let decoder: JSONDecoder

    init(session: Session) {
        self.session = session
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder = decoder
    }

    func send<Response: Decodable & Sendable>(_ endpoint: TMDBEndpoint) async throws -> Response {
        let result = await session.request(endpoint)
            .validate()
            .serializingDecodable(Response.self, decoder: decoder)
            .result
        switch result {
        case .success(let response):
            return response
        case .failure(let error) where error.isExplicitlyCancelledError:
            throw CancellationError()
        case .failure(let error):
            throw NetworkError(error)
        }
    }
}
```

#### Endpoint Enum

- **One case per endpoint**. Path IDs are labeled associated values (`movieID:`, `accountObjectID:`). Query parameters come as `parameters: <Name>DTO.Parameters` and a JSON body as `request: <Name>DTO.Request`.
- **Exhaustive switches**: `method`, `path`, `parameters`, `body` and `authorization` switch over every case with no `default`, so a new case doesn't compile until each property handles it.
- **Encoding**: `asURLRequest()` always encodes `parameters` into the query string and `body` as JSON, so one request can carry both (e.g. `session_id` in the query and a JSON body). Both encoders use `.convertToSnakeCase`. The query encoder sends booleans as `true`/`false` (Alamofire's default is `1`/`0`).
- **No redundant endpoints**. Before adding a case, check whether one of these already covers it:
  - `append_to_response` on `movieDetails` or `personDetails`. Credits, videos, images, reviews, release dates, watch providers, recommendations and account states all come back that way.
  - An existing case with a category enum, e.g. `movieList(category:)` for now playing, popular, top rated and upcoming.
- **Adding an endpoint**:
  1. Create `Data/DTOs/<Group>/<Name>DTO.swift`.
  2. Add the case and handle it in every switch.
  3. Add a row to `TMDBEndpointExpectation.all` in `TMDBEndpointTests`.
  4. Add a decoding test if the DTO has custom coding keys or an `init(from:)`.

Trimmed to two cases (the real file has every endpoint and the `authorization` property):

```swift
import Alamofire
import Foundation

nonisolated enum TMDBEndpoint {
    case movieDetails(movieID: Int, parameters: MovieDetailsDTO.Parameters)
    case addFavorite(accountID: Int, parameters: AddFavoriteDTO.Parameters, request: AddFavoriteDTO.Request)
}

// `nonisolated` is required here. Under default MainActor isolation, extension members and the
// conformances they declare are main-actor-isolated even when the enum itself is `nonisolated`.
nonisolated extension TMDBEndpoint {
    private static let baseURL = "https://api.themoviedb.org"

    private static let queryEncoder = URLEncodedFormParameterEncoder(
        encoder: URLEncodedFormEncoder(boolEncoding: .literal, keyEncoding: .convertToSnakeCase),
        destination: .queryString
    )

    private static let bodyEncoder: JSONParameterEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return JSONParameterEncoder(encoder: encoder)
    }()

    var method: HTTPMethod {
        switch self {
        case .movieDetails:
            .get
        case .addFavorite:
            .post
        }
    }

    var path: String {
        switch self {
        case .movieDetails(let movieID, _):
            "/3/movie/\(movieID)"
        case .addFavorite(let accountID, _, _):
            "/3/account/\(accountID)/favorite"
        }
    }

    var parameters: (any Encodable & Sendable)? {
        switch self {
        case .movieDetails(_, let parameters):
            parameters
        case .addFavorite(_, let parameters, _):
            parameters
        }
    }

    var body: (any Encodable & Sendable)? {
        switch self {
        case .movieDetails:
            nil
        case .addFavorite(_, _, let request):
            request
        }
    }
}

// MARK: - URLRequestConvertible
nonisolated extension TMDBEndpoint: URLRequestConvertible {
    func asURLRequest() throws -> URLRequest {
        var request = try URLRequest(url: Self.baseURL + path, method: method)
        if let parameters {
            request = try Self.queryEncoder.encode(parameters, into: request)
        }
        if let body {
            request = try Self.bodyEncoder.encode(body, into: request)
        }
        return request
    }
}
```

#### DTOs

- **One file per endpoint**: an `enum <Name>DTO` namespace holding up to three types. Leave out the ones the endpoint doesn't use:
  - `Parameters` (`Encodable`): the query string.
  - `Request` (`Encodable`): the JSON body.
  - `Response` (`Decodable`).
- **Shared shapes** live in `Data/DTOs/Shared/` and are reused through `typealias`: `PageDTO<MovieSummaryDTO>`, `StatusDTO`, `SessionParametersDTO`, `GenreDTO`, `ImageDTO`.
- **Isolation**: declare the namespace `nonisolated enum <Name>DTO`, so every type nested in its body inherits `nonisolated`. Types declared in an extension of the namespace need `nonisolated extension <Name>DTO`. Mark every DTO type `Sendable`.
- **Keys**: properties are camelCase. Encoders use `.convertToSnakeCase` and `APIClient`'s decoder uses `.convertFromSnakeCase`. Write a `CodingKeys` raw value only where the conversion can't produce the name:
  - **Acronyms when decoding**: `imdb_id` becomes `imdbId`, so write `case imdbID = "imdbId"`. Encoding needs nothing: `sessionID` already becomes `session_id`.
  - **ISO codes**: `case languageCode = "iso6391"` and `case countryCode = "iso31661"`.
  - **Dotted and slashed keys**: `"vote_count.gte"`, `"watch/providers"`.
- **Parameter values**:
  - Optional parameters are `var` optionals, so `nil` leaves the key out.
  - Booleans are non-optional (`var includeAdult = false`), because lint's `discouraged_optional_boolean` flags `Bool?`.
  - Comma-joined values such as `append_to_response` are typed enum arrays, joined in a custom `encode(to:)`.
- **Flattened JSON**: when extra fields sit next to movie fields in the same object (rated movies, person credits), decode `MovieSummaryDTO(from: decoder)` and then read the extra keys from the same decoder.

```swift
nonisolated enum AddFavoriteDTO {
    typealias Parameters = SessionParametersDTO

    struct Request: Encodable, Sendable {
        let mediaType = "movie"
        let mediaID: Int
        let favorite: Bool
    }

    typealias Response = StatusDTO
}
```

```swift
nonisolated enum CreateSessionFromAccessTokenDTO {
    struct Request: Encodable, Sendable {
        let accessToken: String
    }

    struct Response: Decodable, Sendable {
        let sessionID: String
        let success: Bool

        private enum CodingKeys: String, CodingKey {
            case sessionID = "sessionId"
            case success
        }
    }
}
```

#### Auth

- **Sign-in uses v4**:
  1. `createRequestToken`.
  2. The user approves at `https://www.themoviedb.org/auth/access?request_token=…`. This is a web page, not an API endpoint.
  3. `createAccessToken` returns the user access token and the `accountObjectID` used in `/4/account/…` paths.
- **Writes are v3**: v4 has no favorite, watchlist or rating endpoints. Those take a `session_id` from `createSessionFromAccessToken`.
- **Sign-out** calls both `deleteAccessToken` and `deleteSession`.
- **Tokens**: `TMDBEndpoint.authorization` says which bearer token a request needs:
  - `.userAccessToken` for the v4 account lists.
  - `.readAccessToken`, the app's API read token, for everything else, including the v4 auth calls and the v3 writes.
- **Attaching the token**: do it in a `RequestInterceptor` in `Data/Network/`, never by setting the header by hand. Pass the read-token interceptor to `Session(interceptor:)`. `APIClient` passes the user-token interceptor per request (`session.request(endpoint, interceptor:)`) when `endpoint.authorization == .userAccessToken`.
- **Callback exception**: Alamofire's interceptor API is callback-based. Implementing it is the one allowed exception to the no-completion-handler rule.

## Concurrency

- Swift 6 strict concurrency is on. Fix every diagnostic properly. Never silence one with `@unchecked Sendable`, `nonisolated(unsafe)` or `@preconcurrency` unless the user approves and a comment explains why.
- The app target sets `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` and `SWIFT_APPROACHABLE_CONCURRENCY = YES`. This has several consequences:
  - Scene types are implicitly `@MainActor`. Don't add the annotation again.
  - **Declare every top-level Domain and Data type `nonisolated`**: entities, DTOs and DTO namespaces, repository protocols, and their implementations. Scene Workers follow the same rule (see VIP Scene). Make them `Sendable` as well. Otherwise their `Decodable`, `Hashable` and similar conformances become main-actor-isolated and fail off the main actor.
  - **Nested types inherit, extensions don't**:
    - A type declared inside another type's body takes the enclosing type's isolation. Inside a `nonisolated` type it needs no annotation. Inside a main-actor type, such as a scene's `enum MovieListModel`, it is `@MainActor` unless marked `nonisolated`, like `MovieListModel.DisplayedMovie`.
    - An extension does not inherit. Its members, the types declared in it and the conformances it adds all default to `@MainActor`, even on a `nonisolated` type. Write `nonisolated extension` for extensions of Domain and Data types.
  - **Why this is easy to miss**: the compiler reports it only where nonisolated code uses the member or conformance directly (`conformance of ... crosses into main actor-isolated code`, `main actor-isolated conformance ... cannot be used in nonisolated context`). It stays silent when the only use is inside compiler-synthesized `Codable` code, or inside `try await`, where the `await` quietly hops to the main actor.
  - **Diffable data source identifiers must be `nonisolated` + `Hashable` + `Sendable`**, like `MovieListModel.DisplayedMovie`. Without that you get the compile error `main actor-isolated conformance ... cannot satisfy conformance requirement for a 'Sendable' type parameter`.
  - A `nonisolated async` function runs on the caller's actor. Put CPU-heavy work (image processing, decoding outside `APIClient`) in `@concurrent` functions so it leaves the main actor.
- Use async/await everywhere:
  - No completion handlers, GCD (`DispatchQueue`), Combine or `OperationQueue`. The one exception is implementing Alamofire's `RequestInterceptor`.
  - Use Alamofire's async API (`serializingDecodable`), not its `response…` handlers.
  - Bridge other callback APIs with `withCheckedThrowingContinuation`.
  - Use `AsyncStream` / `AsyncSequence` for streams of values.
- Use an `actor` for shared mutable state that lives off the main actor, such as caches.
- The ViewController owns each `Task` it starts. Store the task, cancel it in `isolated deinit` or when its work becomes irrelevant, and capture dependencies (`[interactor]`) rather than `self`. Avoid `Task.detached`.
- `I<Scene>Interactor` methods that do work are `async` so tests can `await` them directly. `I<Scene>Presenter` and `I<Scene>ViewController` methods are synchronous.
- Treat `CancellationError` as a normal outcome. Never present it as a failure.
- The test targets have no default isolation. Mark suites and test doubles that touch scene types `@MainActor`.

## UIKit

- **UIKit only.** No `import SwiftUI` and no `UIHostingController`; lint reports an error for them. `#Preview { ... }` works with UIKit alone and is allowed.
- **Build all UI in code.** No storyboards, xibs, `@IBOutlet` or `@IBAction`; lint reports an error for them. Info.plist generates the launch screen.
- Lay out views with Auto Layout anchors and `NSLayoutConstraint.activate`, setting `translatesAutoresizingMaskIntoConstraints = false`.
- For lists, use `UICollectionView` with a compositional layout (`.list(using:)` for list screens), `UICollectionViewDiffableDataSource`, `CellRegistration` and content configurations. Don't use `UITableView` in new code.
- Show empty, error and loading states with `contentUnavailableConfiguration`.
- Declare subviews as `private lazy var`, each built by a `make…()` method. Move complex screen layout into a custom `UIView` subclass under `Views/` so the ViewController stays thin.
- Implement `required init?(coder:)` with `fatalError("init(coder:) has not been implemented")`, and don't mark it `@available(*, unavailable)`.
- **Design system**: Fonts, colors, spacing and radii come from the `MovieAppDS` package. Every file that uses them needs `import MovieAppDS` (`MemberImportVisibility` is on). Change design tokens in the package, never in the app.
- **Colors**: use `UIColor.MVColor(_:)` with an `MVColors` case (`view.backgroundColor = .MVColor(.backgroundPrimary)`). Where the context isn't `UIColor`, such as an attributes dictionary, write `UIColor.MVColor(.textPrimary)`. The color catalog lives in the package, each color with a dark variant. A new color needs an asset in the package catalog and an `MVColors` case. No string names, and no `#colorLiteral` / `#imageLiteral`.
- **Fonts**: use `UIFont.MVFont(_:)` with an `MVFonts` case (`label.font = .MVFont(.body)`), Lexend scaled with `UIFontMetrics`. Where the context isn't `UIFont`, such as an attributes dictionary, write `UIFont.MVFont(.largeTitle)`. The font files ship in the package and `AppDelegate` registers them with `FontRegistrar.registerFonts()` at launch, before the first font is made. Don't add `UIAppFonts` back.
- **Strings**: write every user-facing string as `String(localized:)` backed by a String Catalog. Only the Presenter and the ViewController produce display strings.
- **Accessibility**: support Dynamic Type (`MVFont` styles with `adjustsFontForContentSizeCategory = true`), use semantic colors (`.label`, `.systemBackground`), and add accessibility labels on icon-only controls. Support both light and dark mode.

## Code Style (Kodeco)

SwiftLint enforces most of these rules. You are responsible for the rest.

- **Spacing**:
  - Indent with 4 spaces, never tabs. This overrides Kodeco's 2-space rule.
  - Lines warn at 120 characters and error at 160.
  - Open braces on the same line.
  - Leave one blank line between methods, none after `{` or before `}`, and never more than one in a row.
- **Naming**:
  - Prefer clarity over brevity, and don't abbreviate.
  - Use `UpperCamelCase` for types and `lowerCamelCase` for everything else.
  - Keep acronyms in uniform case (`movieID`, `urlString`).
  - Booleans read as assertions (`isLoading`, `hasNextPage`).
  - Factory methods start with `make`.
  - Scene boundary protocols take an `I` prefix (`IMovieListInteractor`). This is a project rule; see VIP Scene.
  - Delegate methods take the source object as an unnamed first parameter.
  - Use US English.
- **Organization**:
  - Order members as properties, `init`, lifecycle, then methods.
  - Put each protocol conformance in its own extension under `// MARK: - <Protocol>`.
  - Put helpers in a `private extension`.
  - Delete unused code and template leftovers.
  - Import only what you use, sorted.
- **Classes**: mark every class `final` unless it is designed for inheritance. Use a `struct` for values and a `class` for identity or lifecycle.
- **Access control**: default to `private`. Use `fileprivate` only when the compiler needs it. Never write `internal`.
- **`self`**: omit it unless the compiler requires it.
- **Types**:
  - Let the compiler infer types. Annotate empty collections (`var movies: [Movie] = []`).
  - Use shorthand syntax (`[String]`, `Int?`).
  - Write `any` on every existential (`any IDiscoverPresenter`, `any Error`, `(any IHomeViewController)?`). Both targets set `SWIFT_UPCOMING_FEATURE_EXISTENTIAL_ANY = YES`, so a bare protocol type is a compile error. Use `some` or a generic instead when the concrete type is fixed and dispatch cost matters.
  - Prefer `let` over `var`.
  - Put constants in case-less enums (`enum Layout { static let spacing: CGFloat = 16 }`).
- **Golden path**:
  - Exit early with `guard` instead of nesting conditions.
  - A `guard` `else` block only exits (return, throw, break, continue, `fatalError`).
  - Use `if let value` / `guard let value` shorthand.
- **Optionals**:
  - No force unwrap, force cast, force try, or implicitly unwrapped optionals. Lint reports an error for each.
  - In tests, use `#require`.
- **Closures**:
  - Use a trailing closure only when a single closure is the last argument.
  - Give closure parameters descriptive names.
  - Use implicit returns in single-expression closures and getters.
- **Memory**:
  - Capture `[weak self]`, then `guard let self else { return }`. Never capture `unowned`.
  - Mark delegates `weak`.
- **Minor**:
  - Omit `get` on read-only computed properties.
  - No semicolons, no parentheses around conditions, and no emoji in code.
  - Open a multi-line string with `"""` on the assignment line.
- **Logging**: use `os.Logger`. `print` produces a lint warning.

### Comments

Code explains *what*. Comments exist only for a non-obvious *why*, such as a constraint, a workaround or a link to a bug.

- No comments that restate the code.
- No commented-out code.
- No Xcode file header blocks.
- No doc comments on self-explanatory internal APIs.
- `// MARK: -` is fine for organizing a file.
- In tests, the `// Given`, `// When` and `// Assert` markers are required (see Testing). Don't add other narration to test bodies.
- `TODO` / `FIXME` trigger lint warnings. Resolve them, or reference a ticket, before merging.

## SwiftLint

- **Config**: `.swiftlint.yml` starts from Kodeco's base rules, adds stricter opt-in rules, and defines custom rules.
- **Custom rules**:
  - Errors: `no_swiftui`, `no_combine`, `no_storyboard_or_nib`.
  - Warnings: `no_dispatch_queue`, `no_print`.
- **Build phase**: the `MovieApp` target's **SwiftLint** Run Script phase runs after Compile Sources on every build. It lints `MovieApp` and `MovieAppTests`. Violations show as Xcode warnings and errors, and errors fail the build.
- **Sandboxing**: the app target sets `ENABLE_USER_SCRIPT_SANDBOXING = NO` so SwiftLint can read the sources. Don't revert it, and don't remove the phase.
- **Install**: `brew install swiftlint`. The script adds `/opt/homebrew/bin` to `PATH`. If SwiftLint is missing, the build only prints a warning.
- **No global disables**: never turn off a rule in `.swiftlint.yml` just to get a green build. For an unavoidable exception, use `// swiftlint:disable:next <rule>` on a single line, with the reason in a comment above it.
- **Analyzer rules**: `unused_import` and `unused_declaration` need a compiler log, which requires a build, so run them only when the user asks. Save the `xcodebuild` output to `build.log`, then run `swiftlint analyze --compiler-log-path build.log`.

## Testing

- Write unit tests with Swift Testing (`import Testing`, `@Test`, `#expect`, `#require`). Don't use XCTest.
- Mirror the source folder structure in `MovieAppTests/`.
- Test every Interactor, Presenter, Worker and DTO mapping.
- For VIP, test each component in isolation, with test doubles at its boundaries:
  - **Interactor**: stub the Worker (a private `<Scene>WorkerStub`), add a `PresenterSpy`, and assert on the `Response`.
  - **Worker**: pass the shared repository stubs from `MovieAppTests/TestDoubles/`, and assert on the result and on the calls the stub recorded (`repository.calls == [.details(7)]`). Workers are nonisolated, so their suites need no `@MainActor`.
  - **Presenter**: add a `ViewControllerSpy` and assert on the `ViewData` values and strings.
  - **ViewController** (for logic that matters): add an `InteractorSpy` and a `RouterSpy`, and assert on the requests and routes that user events trigger.
- **Coordinators**: inject `SceneFactorySpy`, call the routing closure it captured, and assert on the root view controller and the scenes requested. Keep the coordinator in a stored property of the suite: its closures capture it `[weak self]`, and a local constant can be released before the closure runs.
- Name test doubles after their protocol, dropping a scene protocol's `I`: `<Name>Spy` records calls and `<Name>Stub` returns canned results (`MovieListPresenterSpy` for `IMovieListPresenter`, `MovieListWorkerStub` for `IMovieListWorker`). Keep them `private` to the test file. Shared ones go in `MovieAppTests/TestDoubles/`.
- Test names describe behavior: `loadMoviesPresentsFetchedMovies()`.
- **Given / When / Assert**: split each test body into blocks separated by one blank line, and open each block with its marker comment and nothing else:
  - `// Given`: inputs, stubs and the system under test.
  - `// When`: the one call under test.
  - `// Assert`: the checks.
  - Leave out a marker whose block would be empty. A suite whose `init` already builds the SUT starts at `// When`, and a test that only reads a computed property of a value built in Given has no `// When`.
  - When the call has to sit inside `#expect(throws:)`, mark that block `// When & Assert`.
- `await` async business methods directly. No sleeps and no `XCTestExpectation` for async/await code.
- Unit tests never touch the network. To test `APIClient` and repositories, build the `Session` from `URLSessionConfiguration.af.ephemeral` with `protocolClasses = [URLProtocolStub.self]` and return canned responses from the stub. The stub keys responses by URL and tests run in parallel, so each test must stub a URL no other test uses (for example, its own page number).
- `TMDBEndpointTests` checks every endpoint's method, URL and body through one parameterized table, `TMDBEndpointExpectation.all`. Add a row for each new case.
- Decode DTO fixtures with `TMDBJSON.decode(_:from:)` from `MovieAppTests/Fixtures/`. It uses the same `.convertFromSnakeCase` strategy as `APIClient`. Keep fixture JSON inline and minimal: the required fields, plus the ones the test asserts.
- The project has no UI test target for now. Don't add one, or any UI tests, unless the user asks.

```swift
@testable import MovieApp
import Testing

@MainActor
struct MovieListInteractorTests {
    private let presenter = MovieListPresenterSpy()

    @Test
    func loadMoviesPresentsFetchedMovies() async throws {
        // Given
        let movies = [Movie(id: 1, title: "Dune", releaseDate: nil)]
        let sut = MovieListInteractor(
            presenter: presenter,
            worker: MovieListWorkerStub(result: .success(movies))
        )

        // When
        await sut.loadMovies(request: MovieListModel.LoadMovies.Request())

        // Assert
        let response = try #require(presenter.presentMoviesResponses.first)
        #expect(try response.result.get() == movies)
    }
}

@MainActor
private final class MovieListPresenterSpy: IMovieListPresenter {
    private(set) var presentMoviesResponses: [MovieListModel.LoadMovies.Response] = []

    func presentMovies(response: MovieListModel.LoadMovies.Response) {
        presentMoviesResponses.append(response)
    }
}

private struct MovieListWorkerStub: IMovieListWorker {
    let result: Result<[Movie], any Error>

    func fetchPopularMovies(page: Int) async throws -> [Movie] {
        try result.get()
    }
}
```

## Do Not

- Build, test or run the project unless the user explicitly asks.
- Use SwiftUI, Combine, GCD, storyboards, xibs or Interface Builder outlets.
- Force unwrap, force cast, force try, or declare implicitly unwrapped optionals.
- Put business logic in a ViewController, import UIKit in Domain, an Interactor or a Presenter, or let DTOs leave the Data layer.
- Create singletons or global mutable state, or reach across scenes directly.
- Silence concurrency errors with `@unchecked Sendable`, `nonisolated(unsafe)` or `@preconcurrency`.
- Edit `project.pbxproj` to add files, or change build settings, unless asked.
- Add third-party dependencies without asking first.
- Import Alamofire outside `Data/Network/`, `App/` and Data-layer tests, use `AF` / `Session.default`, or let `AFError` escape `APIClient`.
- Import Nuke outside `Common/Images/` and `App/`, or use `ImagePipeline.shared` / `ImageCache.shared`.
- Import CoreData outside `Data/Persistence/CoreData/` and its tests, or let an `NSManagedObject` leave a repository.
- Push or present view controllers from a scene. Routers call coordinator closures.
- Add a TMDB endpoint that `append_to_response` or an existing `TMDBEndpoint` case already covers, or add a `default:` to the `TMDBEndpoint` switches.
- Add comments that describe what the code already says.
- Disable SwiftLint rules globally, remove the SwiftLint build phase, or re-enable script sandboxing on the app target.
