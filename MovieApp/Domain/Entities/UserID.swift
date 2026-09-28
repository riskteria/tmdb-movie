import Foundation

nonisolated struct UserID: Hashable, Sendable {
    let rawValue: String

    static func local(_ uuid: UUID) -> UserID {
        UserID(rawValue: "local:\(uuid.uuidString.lowercased())")
    }
}
