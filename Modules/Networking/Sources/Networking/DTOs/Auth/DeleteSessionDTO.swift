public nonisolated enum DeleteSessionDTO {
    public struct Request: Encodable, Sendable {
        public let sessionID: String

        public init(sessionID: String) {
            self.sessionID = sessionID
        }
    }

    public struct Response: Decodable, Sendable {
        public let success: Bool
    }
}
