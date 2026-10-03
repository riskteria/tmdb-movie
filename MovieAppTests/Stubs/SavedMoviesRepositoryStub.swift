@testable import MovieApp

struct SavedMoviesRepositoryStub: SavedMoviesRepository {
    let savedMovies: [SavedMovie]

    var isPersistent: Bool {
        true
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

    func save(_ movie: Movie) async throws {}

    func remove(_ movieID: Movie.ID) async throws {}

    func removeAll() async throws {}
}
