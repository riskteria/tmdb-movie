public nonisolated enum DeleteSessionDTO {
    public struct Request: Encodable, Sendable {
        public let sessionID: String
    }

    public struct Response: Decodable, Sendable {
        public let success: Bool
    }
}
