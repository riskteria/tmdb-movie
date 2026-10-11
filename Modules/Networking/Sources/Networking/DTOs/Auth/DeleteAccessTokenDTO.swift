public nonisolated enum DeleteAccessTokenDTO {
    public struct Request: Encodable, Sendable {
        public let accessToken: String
    }

    public typealias Response = StatusDTO
}
