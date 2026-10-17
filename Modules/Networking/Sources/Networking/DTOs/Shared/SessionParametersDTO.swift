public nonisolated struct SessionParametersDTO: Encodable, Sendable {
    public let sessionID: String

    public init(sessionID: String) {
        self.sessionID = sessionID
    }
}
