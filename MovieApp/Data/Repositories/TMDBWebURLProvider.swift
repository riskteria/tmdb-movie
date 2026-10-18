import Foundation

nonisolated struct TMDBWebURLProvider {
    private let host = "www.themoviedb.org"
}

// MARK: - WebURLProvider
nonisolated extension TMDBWebURLProvider: WebURLProvider {
    func movieURL(for movieID: Movie.ID) -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = host
        components.path = "/movie/\(movieID)"
        return components.url
    }
}
