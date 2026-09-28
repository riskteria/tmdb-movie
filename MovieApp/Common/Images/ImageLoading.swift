import UIKit

protocol ImageLoading: Sendable {
    func image(for url: URL, targetSize: CGSize) async throws -> UIImage
}
