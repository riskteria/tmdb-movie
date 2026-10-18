import Foundation
@testable import MovieApp
import Synchronization
import Testing

@MainActor
struct MovieDetailInteractorTests {
    private let presenter = MovieDetailPresenterSpy()
    private let movie = Movie.fixture(id: 7)
    private let video = Video.fixture(key: "teaser-key")

    @Test
    func loadDetailsPresentsMovieBeforeDetails() async throws {
        // Given
        let details = MovieDetails.fixture(movie: movie)
        let sut = makeSUT(worker: MovieDetailWorkerStub(details: .success(details)))

        // When
        await sut.loadDetails(request: MovieDetailModel.LoadDetails.Request())

        // Assert
        #expect(presenter.responses.map(\.movie) == [movie, movie])
        #expect(presenter.responses.first?.details == nil)
        let loaded = try #require(presenter.responses.last?.details)
        #expect(try loaded.get() == details)
    }

    @Test
    func loadDetailsPresentsFailure() async throws {
        // Given
        let sut = makeSUT(worker: MovieDetailWorkerStub(details: .failure(StubError.failed)))

        // When
        await sut.loadDetails(request: MovieDetailModel.LoadDetails.Request())

        // Assert
        let loaded = try #require(presenter.responses.last?.details)
        #expect(throws: StubError.failed) {
            try loaded.get()
        }
    }

    @Test
    func loadDetailsPresentsOnlyTheMovieWhenCancelled() async {
        // Given
        let sut = makeSUT(worker: MovieDetailWorkerStub(details: .failure(CancellationError())))

        // When
        await sut.loadDetails(request: MovieDetailModel.LoadDetails.Request())

        // Assert
        #expect(presenter.responses.count == 1)
    }

    @Test
    func observeSavedStatePresentsWhetherMovieIsSaved() async {
        // Given
        let sut = makeSUT(worker: MovieDetailWorkerStub(savedLists: [[makeSavedMovie(id: 7)]]))

        // When
        await sut.observeSavedState(request: MovieDetailModel.ObserveSavedState.Request())

        // Assert
        #expect(presenter.savedStates == [true])
    }

    @Test
    func observeSavedStatePresentsOnlyChanges() async {
        // Given
        let lists = [
            [],
            [makeSavedMovie(id: 1)],
            [makeSavedMovie(id: 7)],
            [makeSavedMovie(id: 7), makeSavedMovie(id: 1)]
        ]
        let sut = makeSUT(worker: MovieDetailWorkerStub(savedLists: lists))

        // When
        await sut.observeSavedState(request: MovieDetailModel.ObserveSavedState.Request())

        // Assert
        #expect(presenter.savedStates == [false, true])
    }

    @Test
    func toggleSaveSavesUnsavedMovie() async {
        // Given
        let worker = MovieDetailWorkerStub(savedLists: [[]])
        let sut = makeSUT(worker: worker)
        await sut.observeSavedState(request: MovieDetailModel.ObserveSavedState.Request())

        // When
        await sut.toggleSave(request: MovieDetailModel.ToggleSave.Request())

        // Assert
        #expect(worker.calls == [.save(7)])
    }

    @Test
    func toggleSaveRemovesSavedMovie() async {
        // Given
        let worker = MovieDetailWorkerStub(savedLists: [[makeSavedMovie(id: 7)]])
        let sut = makeSUT(worker: worker)
        await sut.observeSavedState(request: MovieDetailModel.ObserveSavedState.Request())

        // When
        await sut.toggleSave(request: MovieDetailModel.ToggleSave.Request())

        // Assert
        #expect(worker.calls == [.remove(7)])
    }

    @Test
    func toggleSaveIgnoresTapBeforeStateIsKnown() async {
        // Given
        let worker = MovieDetailWorkerStub()
        let sut = makeSUT(worker: worker)

        // When
        await sut.toggleSave(request: MovieDetailModel.ToggleSave.Request())

        // Assert
        #expect(worker.calls.isEmpty)
    }

    @Test
    func toggleSavePresentsFailure() async throws {
        // Given
        let worker = MovieDetailWorkerStub(savedLists: [[]], save: .failure(StubError.failed))
        let sut = makeSUT(worker: worker)
        await sut.observeSavedState(request: MovieDetailModel.ObserveSavedState.Request())

        // When
        await sut.toggleSave(request: MovieDetailModel.ToggleSave.Request())

        // Assert
        let response = try #require(presenter.toggleSaveResponses.first)
        #expect(response.action == .save)
        #expect(response.movie == movie)
    }

    @Test
    func watchRecordsThenPresentsTrailer() async throws {
        // Given
        let worker = MovieDetailWorkerStub()
        let sut = makeSUT(worker: worker)

        // When
        await sut.watch(request: MovieDetailModel.Watch.Request(video: video))

        // Assert
        #expect(worker.calls == [.startWatching(7, videoKey: "teaser-key")])
        let response = try #require(presenter.watchResponses.first)
        #expect(try response.result.get() == video)
    }

    @Test
    func watchRecordsTheRequestedVideo() async {
        // Given
        let worker = MovieDetailWorkerStub()
        let sut = makeSUT(worker: worker)
        let otherVideo = Video.fixture(key: "official-key")

        // When
        await sut.watch(request: MovieDetailModel.Watch.Request(video: otherVideo))

        // Assert
        #expect(worker.calls == [.startWatching(7, videoKey: "official-key")])
    }

    @Test
    func watchPresentsFailureWhenRecordingFails() async throws {
        // Given
        let sut = makeSUT(worker: MovieDetailWorkerStub(startWatching: .failure(StubError.failed)))

        // When
        await sut.watch(request: MovieDetailModel.Watch.Request(video: video))

        // Assert
        let response = try #require(presenter.watchResponses.first)
        #expect(throws: StubError.failed) {
            try response.result.get()
        }
    }

    @Test
    func cancelledWatchPresentsNothing() async {
        // Given
        let sut = makeSUT(worker: MovieDetailWorkerStub(startWatching: .failure(CancellationError())))

        // When
        await sut.watch(request: MovieDetailModel.Watch.Request(video: video))

        // Assert
        #expect(presenter.watchResponses.isEmpty)
    }
}

private extension MovieDetailInteractorTests {
    func makeSUT(worker: MovieDetailWorkerStub) -> any IMovieDetailInteractor {
        MovieDetailInteractor(movie: movie, presenter: presenter, worker: worker)
    }

    func makeSavedMovie(id: Movie.ID) -> SavedMovie {
        SavedMovie(movie: .fixture(id: id), savedAt: .now)
    }
}

@MainActor
private final class MovieDetailPresenterSpy: IMovieDetailPresenter {
    private(set) var responses: [MovieDetailModel.LoadDetails.Response] = []
    private(set) var savedStates: [Bool] = []
    private(set) var toggleSaveResponses: [MovieDetailModel.ToggleSave.Response] = []
    private(set) var watchResponses: [MovieDetailModel.Watch.Response] = []

    func presentDetails(response: MovieDetailModel.LoadDetails.Response) {
        responses.append(response)
    }

    func presentSavedState(response: MovieDetailModel.ObserveSavedState.Response) {
        savedStates.append(response.isSaved)
    }

    func presentToggleSave(response: MovieDetailModel.ToggleSave.Response) {
        toggleSaveResponses.append(response)
    }

    func presentWatch(response: MovieDetailModel.Watch.Response) {
        watchResponses.append(response)
    }
}

private final class MovieDetailWorkerStub: IMovieDetailWorker {
    enum Call: Equatable {
        case save(Movie.ID)
        case remove(Movie.ID)
        case startWatching(Movie.ID, videoKey: String)
    }

    private let details: Result<MovieDetails, any Error>
    private let savedLists: [[SavedMovie]]
    private let saveResult: Result<Void, any Error>
    private let startWatchingResult: Result<Void, any Error>
    private let recordedCalls = Mutex<[Call]>([])

    var calls: [Call] {
        recordedCalls.withLock { $0 }
    }

    init(
        details: Result<MovieDetails, any Error> = .failure(StubError.failed),
        savedLists: [[SavedMovie]] = [],
        save: Result<Void, any Error> = .success(()),
        startWatching: Result<Void, any Error> = .success(())
    ) {
        self.details = details
        self.savedLists = savedLists
        saveResult = save
        startWatchingResult = startWatching
    }

    func fetchDetails(movieID: Movie.ID) async throws -> MovieDetails {
        try details.get()
    }

    func observeSavedMovies() async -> AsyncStream<[SavedMovie]> {
        AsyncStream { continuation in
            savedLists.forEach { savedMovies in continuation.yield(savedMovies) }
            continuation.finish()
        }
    }

    func saveMovie(_ movie: Movie) async throws {
        recordedCalls.withLock { $0.append(.save(movie.id)) }
        try saveResult.get()
    }

    func removeMovie(_ movieID: Movie.ID) async throws {
        recordedCalls.withLock { $0.append(.remove(movieID)) }
    }

    func startWatching(movieID: Movie.ID, video: Video) async throws {
        recordedCalls.withLock { $0.append(.startWatching(movieID, videoKey: video.key)) }
        try startWatchingResult.get()
    }
}
