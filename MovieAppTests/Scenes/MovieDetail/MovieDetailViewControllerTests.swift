import Foundation
@testable import MovieApp
import Testing
import UIKit

@MainActor
struct MovieDetailViewControllerTests {
    private typealias SUT = UIViewController & IMovieDetailViewController & MovieDetailTabsCellDelegate
    private typealias Snapshot = NSDiffableDataSourceSnapshot<MovieDetailLayout.Section, MovieDetailLayout.Item>
    private typealias DataSource = UICollectionViewDiffableDataSource<MovieDetailLayout.Section, MovieDetailLayout.Item>

    private let interactor = MovieDetailInteractorSpy()
    private let movie = Movie.fixture()
    private let sut: any SUT

    private var snapshot: Snapshot? {
        let collectionView = sut.view.subviews.lazy.compactMap { $0 as? UICollectionView }.first
        return (collectionView?.dataSource as? DataSource)?.snapshot()
    }

    init() {
        let viewController = MovieDetailViewController(
            interactor: interactor,
            router: MovieDetailRouterSpy(),
            imageLoader: ImageLoaderStub()
        )
        viewController.loadViewIfNeeded()
        sut = viewController
    }

    @Test
    func failureShowsTheMessageWithRetry() throws {
        // When
        sut.displayDetails(viewData: .failure(message: "Unable to load this movie"))

        // Assert
        let configuration = try #require(sut.contentUnavailableConfiguration as? UIContentUnavailableConfiguration)
        #expect(configuration.text == "Unable to load this movie")
        #expect(configuration.button.title == "Retry")
    }

    @Test
    func failureClearsTheScreenBehindTheMessage() {
        // Given
        sut.displayDetails(viewData: .loading(makeDetail()))

        // When
        sut.displayDetails(viewData: .failure(message: "Unable to load this movie"))

        // Assert
        #expect(snapshot?.itemIdentifiers.isEmpty == true)
    }

    @Test
    func retryLoadsTheDetailsAgain() async throws {
        // Given
        var loadCalls = interactor.loadDetailsCalls.makeAsyncIterator()
        _ = await loadCalls.next()
        sut.displayDetails(viewData: .failure(message: "Unable to load this movie"))
        let configuration = try #require(sut.contentUnavailableConfiguration as? UIContentUnavailableConfiguration)
        let retry = try #require(configuration.buttonProperties.primaryAction)

        // When
        UIButton(primaryAction: retry).sendActions(for: .primaryActionTriggered)
        _ = await loadCalls.next()

        // Assert
        #expect(interactor.loadDetailsCount == 2)
    }

    @Test
    func loadingAfterAFailureShowsTheScreenAgain() {
        // Given
        sut.displayDetails(viewData: .failure(message: "Unable to load this movie"))

        // When
        sut.displayDetails(viewData: .loading(makeDetail()))

        // Assert
        #expect(sut.contentUnavailableConfiguration == nil)
        #expect(snapshot?.itemIdentifiers.first == .header)
    }

    @Test(.timeLimit(.minutes(1)))
    func closingTheScreenWhileLoadingCancelsTheLoad() async {
        // Given
        let suspendedInteractor = MovieDetailInteractorSpy(suspendsUntilCancelled: true)
        var loadCalls = suspendedInteractor.loadDetailsCalls.makeAsyncIterator()
        var cancellations = suspendedInteractor.cancellations.makeAsyncIterator()
        var closingSUT: (any SUT)? = makeSUT(interactor: suspendedInteractor)
        closingSUT?.loadViewIfNeeded()
        _ = await loadCalls.next()

        // When
        closingSUT = nil
        let cancellation: Void? = await cancellations.next()

        // Assert
        #expect(cancellation != nil)
    }

    @Test
    func closingTheScreenWhileLoadingReleasesIt() {
        // Given
        weak var closedSUT: (any SUT)?

        // When
        autoreleasepool {
            let closingSUT = makeSUT(interactor: MovieDetailInteractorSpy(suspendsUntilCancelled: true))
            closingSUT.loadViewIfNeeded()
            closingSUT.displayDetails(viewData: .loading(makeDetail()))
            closedSUT = closingSUT
        }

        // Assert
        #expect(closedSUT == nil)
    }

    @Test
    func loadingShowsTheLoadingCellBelowTheSynopsis() {
        // When
        sut.displayDetails(viewData: .loading(makeDetail()))

        // Assert
        #expect(snapshot?.itemIdentifiers == [.header, .actions, .synopsis, .status(.loading)])
    }

    @Test
    func contentWithoutCastLeavesOutTheCastSection() {
        // When
        sut.displayDetails(viewData: .content(makeDetail(), makeExtras(cast: [])))

        // Assert
        #expect(snapshot?.sectionIdentifiers.contains(.cast) == false)
    }

    @Test
    func contentWithoutVotesLeavesOutTheRatingRow() {
        // When
        sut.displayDetails(viewData: .content(makeDetail(), makeExtras(rating: nil)))

        // Assert
        #expect(snapshot?.sectionIdentifiers.contains(.rating) == false)
    }

    @Test
    func detailWithoutAnOverviewLeavesOutTheSynopsis() {
        // When
        sut.displayDetails(viewData: .content(makeDetail(overview: ""), makeExtras()))

        // Assert
        #expect(snapshot?.sectionIdentifiers.contains(.synopsis) == false)
    }

    @Test
    func noRecommendationsShowsTheEmptyMessage() {
        // Given
        let extras = makeExtras(moreLikeThis: .empty(message: "No similar movies yet"))

        // When
        sut.displayDetails(viewData: .content(makeDetail(), extras))

        // Assert
        #expect(snapshot?.itemIdentifiers.last == .status(.empty(message: "No similar movies yet")))
    }

    @Test
    func noTrailersShowsTheEmptyMessageOnTheTrailersTab() {
        // Given
        sut.displayDetails(viewData: .content(makeDetail(), makeExtras(trailers: .empty(message: "No trailers yet"))))

        // When
        sut.movieDetailTabsCell(MovieDetailTabsCell(frame: .zero), didSelectTabAt: 1)

        // Assert
        #expect(snapshot?.itemIdentifiers.last == .status(.empty(message: "No trailers yet")))
    }

    private func makeSUT(interactor: MovieDetailInteractorSpy) -> any SUT {
        MovieDetailViewController(
            interactor: interactor,
            router: MovieDetailRouterSpy(),
            imageLoader: ImageLoaderStub()
        )
    }

    private func makeDetail(overview: String = "Paul Atreides unites with the Fremen.") -> MovieDetailModel.DisplayedDetail {
        MovieDetailModel.DisplayedDetail(
            movie: movie,
            title: movie.title,
            metadata: "2024",
            overview: overview,
            artwork: DisplayedArtwork(url: nil, placeholderSeed: movie.id, placeholderTitle: nil),
            watch: .pending
        )
    }

    private func makeExtras(
        rating: MovieDetailModel.DisplayedRating? = nil,
        cast: [MovieDetailModel.DisplayedCastMember] = [],
        moreLikeThis: MovieDetailModel.DisplayedTabContent<MovieDetailModel.DisplayedMovie> = .items([]),
        trailers: MovieDetailModel.DisplayedTabContent<MovieDetailModel.DisplayedTrailer> = .items([])
    ) -> MovieDetailModel.DisplayedExtras {
        MovieDetailModel.DisplayedExtras(rating: rating, cast: cast, moreLikeThis: moreLikeThis, trailers: trailers)
    }
}

@MainActor
private final class MovieDetailInteractorSpy: IMovieDetailInteractor {
    let loadDetailsCalls: AsyncStream<Void>
    let cancellations: AsyncStream<Void>
    private(set) var loadDetailsCount = 0
    private let suspendsUntilCancelled: Bool
    private let loadDetailsContinuation: AsyncStream<Void>.Continuation
    private let cancellationsContinuation: AsyncStream<Void>.Continuation
    private let pendingLoad: AsyncStream<Void>
    private let pendingLoadContinuation: AsyncStream<Void>.Continuation

    init(suspendsUntilCancelled: Bool = false) {
        self.suspendsUntilCancelled = suspendsUntilCancelled
        let loadDetailsStream = AsyncStream<Void>.makeStream()
        loadDetailsCalls = loadDetailsStream.stream
        loadDetailsContinuation = loadDetailsStream.continuation
        let cancellationsStream = AsyncStream<Void>.makeStream()
        cancellations = cancellationsStream.stream
        cancellationsContinuation = cancellationsStream.continuation
        let pendingLoadStream = AsyncStream<Void>.makeStream()
        pendingLoad = pendingLoadStream.stream
        pendingLoadContinuation = pendingLoadStream.continuation
    }

    func loadDetails(request: MovieDetailModel.LoadDetails.Request) async {
        loadDetailsCount += 1
        loadDetailsContinuation.yield()
        guard suspendsUntilCancelled else { return }
        for await _ in pendingLoad {}
        cancellationsContinuation.yield()
    }

    func observeSavedState(request: MovieDetailModel.ObserveSavedState.Request) async {}

    func toggleSave(request: MovieDetailModel.ToggleSave.Request) async {}

    func watch(request: MovieDetailModel.Watch.Request) async {}
}

@MainActor
private final class MovieDetailRouterSpy: IMovieDetailRouter {
    private(set) var movieDetailRequests: [Movie] = []
    private(set) var trailerRequests: [Video] = []
    private(set) var shareRequests: [Movie] = []

    func routeToMovieDetail(movie: Movie) {
        movieDetailRequests.append(movie)
    }

    func routeToTrailer(video: Video) {
        trailerRequests.append(video)
    }

    func routeToShare(movie: Movie) {
        shareRequests.append(movie)
    }
}

private struct ImageLoaderStub: IImageLoader {
    func image(for url: URL, targetSize: CGSize) async throws -> UIImage {
        UIImage()
    }
}
