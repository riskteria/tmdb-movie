nonisolated struct ImageDTO: Decodable, Sendable {
    let filePath: String
    let width: Int
    let height: Int
    let aspectRatio: Double
    let languageCode: String?
    let voteAverage: Double
    let voteCount: Int

    private enum CodingKeys: String, CodingKey {
        case filePath, width, height, aspectRatio
        case languageCode = "iso6391"
        case voteAverage, voteCount
    }
}
