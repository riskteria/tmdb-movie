import Foundation
@testable import MovieApp
import Testing

@MainActor
struct SavedInteractorTests {
    private let presenter = SavedPresenterSpy()

    @Test
    func observeSavedMoviesPresentsEveryChange() async {
        // Given
        let first = SavedMovie(movie: .fixture(id: 1), savedAt: .now)
        let second = SavedMovie(movie: .fixture(id: 2), savedAt: .now)
        let sut = makeSUT(emissions: [[first], [second, first]])

        // When
        await sut.observeSavedMovies(request: SavedModel.ObserveSavedMovies.Request())

        // Assert
        #expect(presenter.responses.map(\.savedMovies) == [[first], [second, first]])
        #expect(presenter.responses.map(\.capacity) == [50, 50])
    }

    private func makeSUT(emissions: [[SavedMovie]]) -> any ISavedInteractor {
        SavedInteractor(presenter: presenter, worker: SavedWorkerStub(emissions: emissions))
    }
}

@MainActor
private final class SavedPresenterSpy: ISavedPresenter {
    private(set) var responses: [SavedModel.ObserveSavedMovies.Response] = []

    func presentSavedMovies(response: SavedModel.ObserveSavedMovies.Response) {
        responses.append(response)
    }
}

// Emits each list in order, then finishes, so the observing Interactor returns.
private struct SavedWorkerStub: ISavedWorker {
    let emissions: [[SavedMovie]]

    func observeSavedMovies() async -> AsyncStream<[SavedMovie]> {
        AsyncStream { continuation in
            emissions.forEach { savedMovies in continuation.yield(savedMovies) }
            continuation.finish()
        }
    }
}
