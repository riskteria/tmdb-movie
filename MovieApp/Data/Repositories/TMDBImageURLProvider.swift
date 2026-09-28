import Foundation

nonisolated struct TMDBImageURLProvider {}

// MARK: - ImageURLProviding
nonisolated extension TMDBImageURLProvider: ImageURLProviding {
    private static let baseURL = "https://image.tmdb.org/t/p/"

    func url(for path: ImagePath, size: ImageSize) -> URL? {
        URL(string: Self.baseURL + Self.sizeName(for: size) + path.rawValue)
    }

    private static func sizeName(for size: ImageSize) -> String {
        switch size {
        case .posterSmall, .profile:
            "w185"
        case .posterMedium:
            "w500"
        case .backdropMedium:
            "w780"
        case .backdropLarge:
            "w1280"
        }
    }
}
