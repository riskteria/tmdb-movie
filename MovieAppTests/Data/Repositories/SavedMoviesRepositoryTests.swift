import Foundation
@testable import MovieApp
import Testing

struct SavedMoviesRepositoryTests {
    @Test
    func saveListsNewestFirstAndMovesResavedMovieToTop() async throws {
        // Given
        let sut: any ISavedMoviesRepository = SavedMoviesRepository(savedMovies: [])

        // When
        try await sut.save(.fixture(id: 1))
        try await sut.save(.fixture(id: 2))
        try await sut.save(.fixture(id: 1))

        // Assert
        #expect(try await sut.all().map(\.id) == [1, 2])
    }

    @Test
    func changesStartWithCurrentListThenReportRemovals() async throws {
        // Given
        let sut: any ISavedMoviesRepository = SavedMoviesRepository(
            savedMovies: [SavedMovie(movie: .fixture(id: 1), savedAt: .now)]
        )
        var changes = await sut.changes.makeAsyncIterator()

        // When
        let initial = await changes.next(isolation: #isolation)
        try await sut.remove(1)
        let afterRemoval = await changes.next(isolation: #isolation)

        // Assert
        #expect(initial?.map(\.id) == [1])
        #expect(afterRemoval?.isEmpty == true)
    }

    @Test
    func reportsThatItDoesNotPersist() {
        // Given
        let sut: any ISavedMoviesRepository = SavedMoviesRepository(savedMovies: [])

        // Assert
        #expect(!sut.isPersistent)
    }
}
