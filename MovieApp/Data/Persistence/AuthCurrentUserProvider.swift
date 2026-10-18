nonisolated protocol CurrentUserProvider: Sendable {
    var userIDs: AsyncStream<UserID> { get async }
}

nonisolated struct AuthCurrentUserProvider {
    let authRepository: any IAuthRepository
    let guestID: UserID
}

// MARK: - CurrentUserProvider
nonisolated extension AuthCurrentUserProvider: CurrentUserProvider {
    var userIDs: AsyncStream<UserID> {
        get async {
            let states = await authRepository.changes
            let guestID = guestID
            return AsyncStream { continuation in
                let mapping = Task {
                    var lastUserID: UserID?
                    for await state in states {
                        let userID = switch state {
                        case .signedOut:
                            guestID
                        case .signedIn(let account):
                            UserID(accountID: account.id)
                        }
                        guard userID != lastUserID else { continue }
                        lastUserID = userID
                        continuation.yield(userID)
                    }
                    continuation.finish()
                }
                continuation.onTermination = { _ in mapping.cancel() }
            }
        }
    }
}
