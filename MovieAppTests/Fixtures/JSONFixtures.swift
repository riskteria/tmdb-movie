import Foundation
import Testing

enum JSONFixture {
    enum JSONFiles: String {
        case movieGenres = "movie-genres"
        case moviePage = "movie-page"
        case movieDetails = "movie-details"
    }

    static func named(_ name: JSONFiles) throws -> String {
        let url = try #require(
            Bundle(for: BundleToken.self).url(forResource: name.rawValue, withExtension: "json"),
            "\(name.rawValue).json isn't in the MovieAppTests bundle"
        )

        return try String(contentsOf: url, encoding: .utf8)
    }
}

private final class BundleToken {}
