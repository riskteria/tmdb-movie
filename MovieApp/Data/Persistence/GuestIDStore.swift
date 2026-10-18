import Foundation

nonisolated struct GuestIDStore: Sendable {
    private let key = "guest.id"
    private let suiteName: String?

    init(suiteName: String? = nil) {
        self.suiteName = suiteName
    }

    func loadOrCreate() -> UserID {
        let defaults = UserDefaults(suiteName: suiteName) ?? .standard
        if let storedID = defaults.string(forKey: key).flatMap(UUID.init(uuidString:)) {
            return UserID(guestID: storedID)
        }
        let guestID = UUID()
        defaults.set(guestID.uuidString, forKey: key)
        return UserID(guestID: guestID)
    }
}
