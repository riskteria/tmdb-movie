import Foundation

nonisolated struct YouTubeURLProvider {
    private let thumbnailHost = "img.youtube.com"
    private let watchHost = "www.youtube.com"
}

// MARK: - VideoURLProvider
nonisolated extension YouTubeURLProvider: VideoURLProvider {
    func thumbnailURL(for video: Video) -> URL? {
        makeURL(host: thumbnailHost, path: "/vi/\(video.key)/hqdefault.jpg")
    }

    func watchURL(for video: Video) -> URL? {
        makeURL(host: watchHost, path: "/watch", queryItems: [URLQueryItem(name: "v", value: video.key)])
    }
}

private nonisolated extension YouTubeURLProvider {
    func makeURL(host: String, path: String, queryItems: [URLQueryItem]? = nil) -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = host
        components.path = path
        components.queryItems = queryItems
        return components.url
    }
}
