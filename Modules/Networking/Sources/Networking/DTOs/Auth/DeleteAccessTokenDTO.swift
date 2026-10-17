public nonisolated enum DeleteAccessTokenDTO {
    public struct Request: Encodable, Sendable {
        public let accessToken: String

        public init(accessToken: String) {
            self.accessToken = accessToken
        }
    }

    public typealias Response = StatusDTO
}
