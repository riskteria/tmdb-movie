nonisolated enum CreateRequestTokenDTO {
    struct Request: Encodable, Sendable {
        var redirectTo: String?
    }

    struct Response: Decodable, Sendable {
        let requestToken: String
        let success: Bool
        let statusCode: Int
        let statusMessage: String
    }
}
