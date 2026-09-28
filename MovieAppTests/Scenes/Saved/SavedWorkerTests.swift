import Foundation
@testable import MovieApp
import Testing

struct SavedWorkerTests {
    @Test
    func observeSavedMoviesStreamsRepositoryChanges() async {
        // Given
        let savedMovies = [SavedMovie(movie: .fixture(id: 1), savedAt: .now)]
        let sut = SavedWorker(savedMoviesRepository: SavedMoviesRepositoryStub(savedMovies: savedMovies))

        // When
        let stream = await sut.observeSavedMovies()

        // Assert
        #expect(await stream.first { _ in true } == savedMovies)
    }
}
