import Foundation
@testable import MovieApp
import Testing

struct SavedWorkerTests {
    @Test
    func observeSavedMoviesStreamsRepositoryChanges() async {
        // Given
        let savedMovies = [SavedMovie(movie: .fixture(id: 1), savedAt: .now)]
        let sut: any ISavedWorker = SavedWorker(
            savedMoviesRepository: SavedMoviesRepositoryStub(savedMovies: savedMovies)
        )

        // When
        let stream = await sut.observeSavedMovies()

        // Assert
        #expect(await stream.first { _ in true } == .signedIn(savedMovies))
    }

    @Test
    func observeSavedMoviesForwardsSignedOut() async {
        // Given
        let sut: any ISavedWorker = SavedWorker(savedMoviesRepository: SavedMoviesRepositoryStub(state: .signedOut))

        // When
        let stream = await sut.observeSavedMovies()

        // Assert
        #expect(await stream.first { _ in true } == .signedOut)
    }

    @Test
    func removeMovieCallsRepository() async throws {
        // Given
        let repository = SavedMoviesRepositoryStub(remove: .success(()))
        let sut: any ISavedWorker = SavedWorker(savedMoviesRepository: repository)

        // When
        try await sut.removeMovie(7)

        // Assert
        #expect(repository.calls == [.remove(7)])
    }}
