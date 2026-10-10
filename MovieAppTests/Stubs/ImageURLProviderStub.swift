import Foundation
@testable import MovieApp

struct ImageURLProviderStub: ImageURLProvider {
    func url(for path: ImagePath, size: ImageSize) -> URL? {
        URL(string: "https://images.test/\(size)\(path.rawValue)")
    }
}
