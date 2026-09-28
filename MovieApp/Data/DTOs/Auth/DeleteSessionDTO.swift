nonisolated enum DeleteSessionDTO {
    struct Request: Encodable, Sendable {
        let sessionID: String
    }

    struct Response: Decodable, Sendable {
        let success: Bool
    }
}
