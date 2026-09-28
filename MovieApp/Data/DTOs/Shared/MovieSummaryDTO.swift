nonisolated struct MovieSummaryDTO: Decodable, Sendable {
    let id: Int
    let title: String
    let originalTitle: String
    let originalLanguage: String
    let overview: String
    let posterPath: String?
    let backdropPath: String?
    let genreIDs: [Int]
    let releaseDate: String?
    let popularity: Double
    let voteAverage: Double
    let voteCount: Int
    let adult: Bool
    let video: Bool

    // Raw values are keys after `.convertFromSnakeCase`, which turns `genre_ids` into `genreIds`.
    private enum CodingKeys: String, CodingKey {
        case id, title, originalTitle, originalLanguage, overview, posterPath, backdropPath
        case genreIDs = "genreIds"
        case releaseDate, popularity, voteAverage, voteCount, adult, video
    }
}
