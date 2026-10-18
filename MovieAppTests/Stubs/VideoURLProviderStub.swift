import Foundation
@testable import MovieApp

struct VideoURLProviderStub: VideoURLProvider {
    func thumbnailURL(for video: Video) -> URL? {
        URL(string: "https://example.com/thumb/\(video.key)")
    }

    func watchURL(for video: Video) -> URL? {
        URL(string: "https://example.com/watch/\(video.key)")
    }
}
