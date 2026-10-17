nonisolated enum AuthState: Hashable, Sendable {
    case signedOut
    case signedIn(Account)
}
