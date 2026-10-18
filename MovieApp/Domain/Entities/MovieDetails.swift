nonisolated struct MovieDetails: Hashable, Sendable {
    let movie: Movie
    let runtime: Duration?
    let genres: [Genre]
    let voteCount: Int
    let tagline: String?
    let certification: String?
    let cast: [CastMember]
    let videos: [Video]
    let recommendations: [Movie]

    var mainTrailer: Video? {
        videos.first { $0.kind == .trailer && $0.isOfficial } ?? videos.first
    }
}
