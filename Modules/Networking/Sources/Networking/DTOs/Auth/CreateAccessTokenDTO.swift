public nonisolated enum CreateAccessTokenDTO {
    public struct Request: Encodable, Sendable {
        public let requestToken: String

        public init(requestToken: String) {
            self.requestToken = requestToken
        }
    }

    public struct Response: Decodable, Sendable {
        public let accessToken: String
        public let accountObjectID: String
        public let success: Bool
        public let statusCode: Int
        public let statusMessage: String

        // `account_id` holds the v4 account object ID, used in `/4/account/{account_object_id}` paths.
        private enum CodingKeys: String, CodingKey {
            case accessToken
            case accountObjectID = "accountId"
            case success, statusCode, statusMessage
        }
    }
}
