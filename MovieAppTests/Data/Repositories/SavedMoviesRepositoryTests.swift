import Foundation
@testable import MovieApp
import Testing

struct SavedMoviesRepositoryTests {
    @Test
    func saveListsNewestFirstAndMovesResavedMovieToTop() async {
        // Given
        let sut = SavedMoviesRepository(savedMovies: [])

        // When
        await sut.save(.fixture(id: 1))
        await sut.save(.fixture(id: 2))
        await sut.save(.fixture(id: 1))

        // Assert
        #expect(await sut.all().map(\.id) == [1, 2])
    }

    @Test
    func changesStartWithCurrentListThenReportRemovals() async {
        // Given
        let sut = SavedMoviesRepository(savedMovies: [SavedMovie(movie: .fixture(id: 1), savedAt: .now)])
        var changes = await sut.changes.makeAsyncIterator()

        // When
        let initial = await changes.next(isolation: #isolation)
        await sut.remove(1)
        let afterRemoval = await changes.next(isolation: #isolation)

        // Assert
        #expect(initial?.map(\.id) == [1])
        #expect(afterRemoval?.isEmpty == true)
    }

    @Test
    func reportsThatItDoesNotPersist() {
        // Given
        let sut = SavedMoviesRepository()

        // Assert
        #expect(!sut.isPersistent)
    }
}
