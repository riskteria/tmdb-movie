nonisolated enum DeleteAccessTokenDTO {
    struct Request: Encodable, Sendable {
        let accessToken: String
    }

    typealias Response = StatusDTO
}
