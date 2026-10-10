import Foundation

nonisolated protocol ImageURLProvider: Sendable {
    func url(for path: ImagePath, size: ImageSize) -> URL?
}
