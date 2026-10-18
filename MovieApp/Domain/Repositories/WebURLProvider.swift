import Foundation

nonisolated protocol WebURLProvider: Sendable {
    func movieURL(for movieID: Movie.ID) -> URL?
}
