import Foundation

nonisolated struct UserID: Hashable, Sendable {
    let rawValue: String

    init(guestID: UUID) {
        rawValue = "local:\(guestID.uuidString.lowercased())"
    }

    init(accountID: Account.ID) {
        rawValue = "tmdb:\(accountID)"
    }
}
