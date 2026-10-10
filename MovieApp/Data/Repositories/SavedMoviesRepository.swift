import Foundation

actor SavedMoviesRepository {
    nonisolated let isPersistent = false
    private var savedMovies: [SavedMovie]
    private let broadcaster = AsyncBroadcaster<[SavedMovie]>()

    init(savedMovies: [SavedMovie] = MockResponseCatalog.savedMovies) {
        self.savedMovies = savedMovies
    }
}

// MARK: - ISavedMoviesRepository
extension SavedMoviesRepository: ISavedMoviesRepository {
    var changes: AsyncStream<[SavedMovie]> {
        get async {
            await broadcaster.subscribe(startingWith: savedMovies)
        }
    }

    func all() -> [SavedMovie] {
        savedMovies
    }

    func contains(_ movieID: Movie.ID) -> Bool {
        savedMovies.contains { $0.id == movieID }
    }

    func save(_ movie: Movie) async {
        savedMovies.removeAll { $0.id == movie.id }
        savedMovies.insert(SavedMovie(movie: movie, savedAt: .now), at: 0)
        await broadcaster.send(savedMovies)
    }

    func remove(_ movieID: Movie.ID) async {
        savedMovies.removeAll { $0.id == movieID }
        await broadcaster.send(savedMovies)
    }

    func removeAll() async {
        savedMovies.removeAll()
        await broadcaster.send(savedMovies)
    }
}
