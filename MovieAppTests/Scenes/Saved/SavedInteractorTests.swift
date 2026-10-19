import Foundation
@testable import MovieApp
import Testing

@MainActor
struct SavedInteractorTests {
    private let presenter = SavedPresenterSpy()
    private let movie = Movie.fixture(id: 7)

    @Test
    func observeSavedMoviesPresentsEveryChange() async {
        // Given
        let first = SavedMovie(movie: .fixture(id: 1), savedAt: .now)
        let second = SavedMovie(movie: .fixture(id: 2), savedAt: .now)
        let sut = makeSUT(worker: SavedWorkerStub(emissions: [.signedIn([first]), .signedIn([second, first])]))

        // When
        await sut.observeSavedMovies(request: SavedModel.ObserveSavedMovies.Request())

        // Assert
        #expect(presenter.responses.map(\.state) == [.signedIn([first]), .signedIn([second, first])])
        #expect(presenter.responses.map(\.capacity) == [50, 50])
    }

    @Test
    func observePassesSignedOut() async {
        // Given
        let sut = makeSUT(worker: SavedWorkerStub(emissions: [.signedOut]))

        // When
        await sut.observeSavedMovies(request: SavedModel.ObserveSavedMovies.Request())

        // Assert
        #expect(presenter.responses.map(\.state) == [.signedOut])
    }

    @Test
    func removeMoviePresentsSuccess() async throws {
        // Given
        let sut = makeSUT(worker: SavedWorkerStub(remove: .success(())))

        // When
        await sut.removeMovie(request: SavedModel.RemoveMovie.Request(movie: movie))

        // Assert
        let response = try #require(presenter.removeResponses.first)
        #expect(response.movie == movie)
        #expect(throws: Never.self) {
            try response.result.get()
        }
    }

    @Test
    func removeMoviePresentsFailure() async throws {
        // Given
        let sut = makeSUT(worker: SavedWorkerStub(remove: .failure(StubError.failed)))

        // When
        await sut.removeMovie(request: SavedModel.RemoveMovie.Request(movie: movie))

        // Assert
        let response = try #require(presenter.removeResponses.first)
        #expect(throws: StubError.failed) {
            try response.result.get()
        }
    }

    private func makeSUT(worker: SavedWorkerStub) -> any ISavedInteractor {
        SavedInteractor(presenter: presenter, worker: worker)
    }
}

@MainActor
private final class SavedPresenterSpy: ISavedPresenter {
    private(set) var responses: [SavedModel.ObserveSavedMovies.Response] = []
    private(set) var removeResponses: [SavedModel.RemoveMovie.Response] = []

    func presentSavedMovies(response: SavedModel.ObserveSavedMovies.Response) {
        responses.append(response)
    }

    func presentRemoveMovie(response: SavedModel.RemoveMovie.Response) {
        removeResponses.append(response)
    }
}

private struct SavedWorkerStub: ISavedWorker {
    var emissions: [AccountScoped<[SavedMovie]>] = []
    var remove: Result<Void, any Error> = .success(())

    func observeSavedMovies() async -> AsyncStream<AccountScoped<[SavedMovie]>> {
        AsyncStream { continuation in
            emissions.forEach { state in continuation.yield(state) }
            continuation.finish()
        }
    }

    func removeMovie(_ movieID: Movie.ID) async throws {
        try remove.get()
    }
}
