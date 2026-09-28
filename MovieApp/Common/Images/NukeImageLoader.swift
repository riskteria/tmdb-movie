import Nuke
import UIKit

final class NukeImageLoader {
    private let pipeline: ImagePipeline

    init(pipeline: ImagePipeline) {
        self.pipeline = pipeline
    }
}

// MARK: - ImageLoading
extension NukeImageLoader: ImageLoading {
    // Downsampling to the view's size keeps decoded images small in memory while scrolling.
    func image(for url: URL, targetSize: CGSize) async throws -> UIImage {
        let request = ImageRequest(url: url, processors: [.resize(size: targetSize)])
        return try await pipeline.image(for: request)
    }
}
