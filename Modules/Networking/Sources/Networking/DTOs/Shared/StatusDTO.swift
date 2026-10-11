public nonisolated struct StatusDTO: Decodable, Sendable {
    public let statusCode: Int
    public let statusMessage: String
}
