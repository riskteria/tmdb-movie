import Foundation

nonisolated struct WatchProgress: Hashable, Sendable {
    private static let finishedThreshold = 0.95

    let contentID: Int
    let mediaType: MediaType
    let position: Duration
    let duration: Duration
    let videoKey: String
    let lastWatchedAt: Date

    var progress: Double {
        guard duration > .zero else { return 0 }
        return min(max(position / duration, 0), 1)
    }

    var remaining: Duration {
        max(duration - position, .zero)
    }

    var isFinished: Bool {
        progress >= Self.finishedThreshold
    }
}
