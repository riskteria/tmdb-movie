nonisolated protocol CurrentUserProvider: Sendable {
    var accountIDs: AsyncStream<Account.ID?> { get async }
}

nonisolated struct AuthCurrentUserProvider {
    let authRepository: any IAuthRepository
}

// MARK: - CurrentUserProvider
nonisolated extension AuthCurrentUserProvider: CurrentUserProvider {
    var accountIDs: AsyncStream<Account.ID?> {
        get async {
            let states = await authRepository.changes
            return AsyncStream { continuation in
                let mapping = Task {
                    var hasYielded = false
                    var lastAccountID: Account.ID?
                    for await state in states {
                        let accountID: Account.ID? = switch state {
                        case .signedOut:
                            nil
                        case .signedIn(let account):
                            account.id
                        }
                        guard !hasYielded || accountID != lastAccountID else { continue }
                        hasYielded = true
                        lastAccountID = accountID
                        continuation.yield(accountID)
                    }
                    continuation.finish()
                }
                continuation.onTermination = { _ in mapping.cancel() }
            }
        }
    }
}
