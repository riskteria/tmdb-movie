import Foundation
@testable import MovieApp
import Testing

struct SavedMoviesRepositoryTests {
    @Test
    func saveListsTheNewestMovieFirst() async throws {
        // Given
        let sut: any ISavedMoviesRepository = SavedMoviesRepository(savedMovies: [makeSavedMovie(id: 1)])

        // When
        try await sut.save(.fixture(id: 2))

        // Assert
        #expect(try await sut.all().map(\.id) == [2, 1])
    }

    @Test
    func savingAgainMovesTheMovieToTheTopWithoutDuplicating() async throws {
        // Given
        let sut: any ISavedMoviesRepository = SavedMoviesRepository(
            savedMovies: [makeSavedMovie(id: 2), makeSavedMovie(id: 1)]
        )

        // When
        try await sut.save(.fixture(id: 1))

        // Assert
        #expect(try await sut.all().map(\.id) == [1, 2])
    }

    @Test
    func containsFindsOnlySavedMovies() async throws {
        // Given
        let sut: any ISavedMoviesRepository = SavedMoviesRepository(savedMovies: [makeSavedMovie(id: 1)])

        // When
        let containsSaved = try await sut.contains(1)
        let containsUnsaved = try await sut.contains(2)

        // Assert
        #expect(containsSaved)
        #expect(!containsUnsaved)
    }

    @Test
    func removeAllEmptiesTheList() async throws {
        // Given
        let sut: any ISavedMoviesRepository = SavedMoviesRepository(
            savedMovies: [makeSavedMovie(id: 1), makeSavedMovie(id: 2)]
        )

        // When
        try await sut.removeAll()

        // Assert
        #expect(try await sut.all().isEmpty)
    }

    @Test
    func changesStartWithTheCurrentList() async {
        // Given
        let sut: any ISavedMoviesRepository = SavedMoviesRepository(savedMovies: [makeSavedMovie(id: 1)])
        var changes = await sut.changes.makeAsyncIterator()

        // When
        let initial = await changes.next(isolation: #isolation)

        // Assert
        #expect(initial?.map(\.id) == [1])
    }

    @Test
    func saveSendsTheUpdatedList() async throws {
        // Given
        let sut: any ISavedMoviesRepository = SavedMoviesRepository(savedMovies: [])
        var changes = await sut.changes.makeAsyncIterator()
        _ = await changes.next(isolation: #isolation)

        // When
        try await sut.save(.fixture(id: 1))
        let afterSave = await changes.next(isolation: #isolation)

        // Assert
        #expect(afterSave?.map(\.id) == [1])
    }

    @Test
    func removeSendsTheUpdatedList() async throws {
        // Given
        let sut: any ISavedMoviesRepository = SavedMoviesRepository(savedMovies: [makeSavedMovie(id: 1)])
        var changes = await sut.changes.makeAsyncIterator()
        _ = await changes.next(isolation: #isolation)

        // When
        try await sut.remove(1)
        let afterRemoval = await changes.next(isolation: #isolation)

        // Assert
        #expect(afterRemoval?.isEmpty == true)
    }

    @Test
    func reportsThatItDoesNotPersist() {
        // Given
        let sut: any ISavedMoviesRepository = SavedMoviesRepository(savedMovies: [])

        // Assert
        #expect(!sut.isPersistent)
    }

    private func makeSavedMovie(id: Movie.ID) -> SavedMovie {
        SavedMovie(movie: .fixture(id: id), savedAt: Date(timeIntervalSince1970: 1_700_000_000))
    }
}
