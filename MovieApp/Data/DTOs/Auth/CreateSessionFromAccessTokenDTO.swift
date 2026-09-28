nonisolated enum CreateSessionFromAccessTokenDTO {
    struct Request: Encodable, Sendable {
        let accessToken: String
    }

    struct Response: Decodable, Sendable {
        let sessionID: String
        let success: Bool

        private enum CodingKeys: String, CodingKey {
            case sessionID = "sessionId"
            case success
        }
    }
}
