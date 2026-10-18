import Foundation

nonisolated protocol VideoURLProvider: Sendable {
    func thumbnailURL(for video: Video) -> URL?
    func watchURL(for video: Video) -> URL?
}
