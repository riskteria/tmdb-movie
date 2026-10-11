public nonisolated enum CreateRequestTokenDTO {
    public struct Request: Encodable, Sendable {
        public var redirectTo: String?
    }

    public struct Response: Decodable, Sendable {
        public let requestToken: String
        public let success: Bool
        public let statusCode: Int
        public let statusMessage: String
    }
}
