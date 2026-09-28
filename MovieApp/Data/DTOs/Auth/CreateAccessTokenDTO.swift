nonisolated enum CreateAccessTokenDTO {
    struct Request: Encodable, Sendable {
        let requestToken: String
    }

    struct Response: Decodable, Sendable {
        let accessToken: String
        let accountObjectID: String
        let success: Bool
        let statusCode: Int
        let statusMessage: String

        // `account_id` holds the v4 account object ID, used in `/4/account/{account_object_id}` paths.
        private enum CodingKeys: String, CodingKey {
            case accessToken
            case accountObjectID = "accountId"
            case success, statusCode, statusMessage
        }
    }
}
