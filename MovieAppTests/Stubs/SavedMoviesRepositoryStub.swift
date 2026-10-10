@testable import MovieApp
import Testing

struct SavedMoviesRepositoryStub: ISavedMoviesRepository {
    let savedMovies: [SavedMovie]

    var isPersistent: Bool {
        Issue.record("Unexpected read of isPersistent")
        return false
    }

    var changes: AsyncStream<[SavedMovie]> {
        get async {
            AsyncStream { continuation in continuation.yield(savedMovies) }
        }
    }

    func all() async throws -> [SavedMovie] {
        savedMovies
    }

    func contains(_ movieID: Movie.ID) async throws -> Bool {
        savedMovies.contains { $0.id == movieID }
    }

    func save(_ movie: Movie) async throws {
        Issue.record("Unexpected call to save(_:)")
    }

    func remove(_ movieID: Movie.ID) async throws {
        Issue.record("Unexpected call to remove(_:)")
    }

    func removeAll() async throws {
        Issue.record("Unexpected call to removeAll()")
    }
}
