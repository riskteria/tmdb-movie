public nonisolated enum CreateSessionFromAccessTokenDTO {
    public struct Request: Encodable, Sendable {
        public let accessToken: String
    }

    public struct Response: Decodable, Sendable {
        public let sessionID: String
        public let success: Bool

        private enum CodingKeys: String, CodingKey {
            case sessionID = "sessionId"
            case success
        }
    }
}
