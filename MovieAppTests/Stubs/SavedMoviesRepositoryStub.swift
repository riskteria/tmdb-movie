@testable import MovieApp
import Synchronization
import Testing

final class SavedMoviesRepositoryStub: ISavedMoviesRepository {
    enum Storage {
        case persistent
        case inMemory
    }

    enum Call: Equatable {
        case save(Movie.ID)
        case remove(Movie.ID)
        case removeAll
    }

    private let savedMovies: [SavedMovie]
    private let storage: Storage?
    private let saveResult: Result<Void, any Error>?
    private let removeResult: Result<Void, any Error>?
    private let removeAllResult: Result<Void, any Error>?
    private let recordedCalls = Mutex<[Call]>([])

    var calls: [Call] {
        recordedCalls.withLock { $0 }
    }

    var isPersistent: Bool {
        guard let storage else {
            Issue.record("Unexpected read of isPersistent")
            return false
        }
        return storage == .persistent
    }

    var changes: AsyncStream<[SavedMovie]> {
        get async {
            AsyncStream { continuation in continuation.yield(savedMovies) }
        }
    }

    init(
        savedMovies: [SavedMovie] = [],
        storage: Storage? = nil,
        save: Result<Void, any Error>? = nil,
        remove: Result<Void, any Error>? = nil,
        removeAll: Result<Void, any Error>? = nil
    ) {
        self.savedMovies = savedMovies
        self.storage = storage
        saveResult = save
        removeResult = remove
        removeAllResult = removeAll
    }

    func all() async throws -> [SavedMovie] {
        savedMovies
    }

    func contains(_ movieID: Movie.ID) async throws -> Bool {
        savedMovies.contains { $0.id == movieID }
    }

    func save(_ movie: Movie) async throws {
        try record(.save(movie.id), result: saveResult, unexpected: "save(_:)")
    }

    func remove(_ movieID: Movie.ID) async throws {
        try record(.remove(movieID), result: removeResult, unexpected: "remove(_:)")
    }

    func removeAll() async throws {
        try record(.removeAll, result: removeAllResult, unexpected: "removeAll()")
    }

    private func record(_ call: Call, result: Result<Void, any Error>?, unexpected name: String) throws {
        guard let result else {
            Issue.record("Unexpected call to \(name)")
            return
        }
        recordedCalls.withLock { $0.append(call) }
        try result.get()
    }
}
