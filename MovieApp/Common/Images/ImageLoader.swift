import Nuke
import UIKit

protocol IImageLoader: Sendable {
    func image(for url: URL, targetSize: CGSize) async throws -> UIImage
}

final class ImageLoader {
    private let pipeline: ImagePipeline

    init(pipeline: ImagePipeline) {
        self.pipeline = pipeline
    }
}

// MARK: - IImageLoader
extension ImageLoader: IImageLoader {
    // Downsampling to the view's size keeps decoded images small in memory while scrolling.
    func image(for url: URL, targetSize: CGSize) async throws -> UIImage {
        let request = ImageRequest(url: url, processors: [.resize(size: targetSize)])
        return try await pipeline.image(for: request)
    }
}
