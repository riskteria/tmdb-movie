public nonisolated struct ImageDTO: Decodable, Sendable {
    public let filePath: String
    public let width: Int
    public let height: Int
    public let aspectRatio: Double
    public let languageCode: String?
    public let voteAverage: Double
    public let voteCount: Int

    private enum CodingKeys: String, CodingKey {
        case filePath, width, height, aspectRatio
        case languageCode = "iso6391"
        case voteAverage, voteCount
    }
}
