import Foundation

nonisolated struct SavedMovie: Identifiable, Hashable, Sendable {
    static let capacity = 50

    let movie: Movie
    let savedAt: Date

    var id: Movie.ID {
        movie.id
    }
}
