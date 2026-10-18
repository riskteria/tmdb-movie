nonisolated struct AuthSession: Codable, Equatable, Sendable {
    let accessToken: String
    let accountObjectID: String
    let sessionID: String
    let accountID: Int
    let username: String
    let name: String
    let avatarPath: String?
}
