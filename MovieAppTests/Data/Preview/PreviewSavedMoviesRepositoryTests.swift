import Foundation
@testable import MovieApp
import Testing

struct PreviewSavedMoviesRepositoryTests {
    @Test
    func saveListsNewestFirstAndMovesResavedMovieToTop() async {
        // Given
        let sut = PreviewSavedMoviesRepository(savedMovies: [])

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
        let sut = PreviewSavedMoviesRepository(savedMovies: [SavedMovie(movie: .fixture(id: 1), savedAt: .now)])
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
        let sut = PreviewSavedMoviesRepository()

        // Assert
        #expect(!sut.isPersistent)
    }
}
