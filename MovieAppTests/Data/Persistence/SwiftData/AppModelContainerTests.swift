import Foundation
@testable import MovieApp
import Testing

final class AppModelContainerTests {
    private let blockingFileURL = FileManager.default.temporaryDirectory
        .appending(path: "AppModelContainerTests.\(UUID().uuidString)")

    deinit {
        try? FileManager.default.removeItem(at: blockingFileURL)
    }

    @Test
    func inMemoryContainerIsNotPersistent() {
        // When
        let sut = AppModelContainer(isStoredInMemoryOnly: true)

        // Assert
        #expect(!sut.isPersistent)
    }

    @Test
    func unopenableStoreFallsBackToMemory() throws {
        // Given
        try Data("not a folder".utf8).write(to: blockingFileURL)

        // When
        let sut = AppModelContainer(storeURL: blockingFileURL.appending(path: "MovieApp.store"))

        // Assert
        #expect(!sut.isPersistent)
    }
}
