import Foundation

nonisolated protocol ImageURLProviding: Sendable {
    func url(for path: ImagePath, size: ImageSize) -> URL?
}
