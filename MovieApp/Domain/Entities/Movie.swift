import Foundation

nonisolated struct Movie: Identifiable, Hashable, Sendable {
    let id: Int
    let title: String
    let overview: String
    let releaseDate: Date?
    let posterPath: ImagePath?
    let backdropPath: ImagePath?
    let genreIDs: [Genre.ID]
    let voteAverage: Double
}
