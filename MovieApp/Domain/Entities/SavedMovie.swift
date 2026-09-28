import Foundation

nonisolated struct SavedMovie: Identifiable, Hashable, Sendable {
    // The requirement's cap. Saving past it evicts the oldest-saved movie (Week 4).
    static let capacity = 50

    let movie: Movie
    let savedAt: Date

    var id: Movie.ID {
        movie.id
    }
}
