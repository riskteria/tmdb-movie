nonisolated struct MovieDetails: Hashable, Sendable {
    let movie: Movie
    let runtime: Duration?
    let genres: [Genre]
    let tagline: String?
    let certification: String?
    let cast: [CastMember]
    let videos: [Video]
    let recommendations: [Movie]
}
