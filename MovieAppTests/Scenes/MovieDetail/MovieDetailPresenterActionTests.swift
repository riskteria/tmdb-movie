@testable import MovieApp
import Testing

@MainActor
struct MovieDetailPresenterActionTests {
    private let viewController = MovieDetailViewControllerSpy()
    private let sut: any IMovieDetailPresenter
    private let movie = Movie.fixture()

    init() {
        let presenter = MovieDetailPresenter(
            imageURLProvider: ImageURLProviderStub(),
            videoURLProvider: VideoURLProviderStub()
        )
        presenter.viewController = viewController
        sut = presenter
    }

    @Test
    func savedStateTitles() {
        // When
        sut.presentSavedState(response: MovieDetailModel.ObserveSavedState.Response(savedState: .signedIn(false)))
        sut.presentSavedState(response: MovieDetailModel.ObserveSavedState.Response(savedState: .signedIn(true)))

        // Assert
        #expect(viewController.displayedSavedStates == [
            .visible(title: "Save", isSaved: false),
            .visible(title: "Saved", isSaved: true)
        ])
    }

    @Test
    func signedOutHidesSave() {
        // When
        sut.presentSavedState(response: MovieDetailModel.ObserveSavedState.Response(savedState: .signedOut))

        // Assert
        #expect(viewController.displayedSavedStates == [.hidden])
    }

    @Test
    func toggleSaveFailureMessages() {
        // When
        sut.presentToggleSave(response: MovieDetailModel.ToggleSave.Response(action: .save, movie: movie))
        sut.presentToggleSave(response: MovieDetailModel.ToggleSave.Response(action: .remove, movie: movie))

        // Assert
        #expect(viewController.displayedToggleSaves.map(\.message) == [
            "Couldn't save “Dune: Part Two”",
            "Couldn't remove “Dune: Part Two”"
        ])
    }

    @Test
    func watchSuccessPassesVideo() {
        // Given
        let video = Video.fixture()

        // When
        sut.presentWatch(response: MovieDetailModel.Watch.Response(movie: movie, result: .success(video)))

        // Assert
        #expect(viewController.displayedWatches == [.trailer(video)])
    }

    @Test
    func watchFailureMessage() {
        // When
        sut.presentWatch(response: MovieDetailModel.Watch.Response(movie: movie, result: .failure(StubError.failed)))

        // Assert
        #expect(viewController.displayedWatches == [
            .failure(message: "Couldn't add “Dune: Part Two” to Continue Watching")
        ])
    }
}
