import Foundation

nonisolated extension String {
    var nonEmpty: String? {
        isEmpty ? nil : self
    }

    func tmdbDate(timeZone: TimeZone = .current) -> Date? {
        try? Date(self, strategy: Date.ISO8601FormatStyle(timeZone: timeZone).year().month().day())
    }

    func tmdbTimestamp() -> Date? {
        try? Date(self, strategy: Date.ISO8601FormatStyle(includingFractionalSeconds: true))
    }
}
