nonisolated struct StatusDTO: Decodable, Sendable {
    let statusCode: Int
    let statusMessage: String
}
