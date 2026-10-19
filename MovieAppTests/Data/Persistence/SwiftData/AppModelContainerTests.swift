import Foundation
@testable import MovieApp
import SwiftData
import Testing

final class AppModelContainerTests {
    private let blockingFileURL = FileManager.default.temporaryDirectory
        .appending(path: "AppModelContainerTests.\(UUID().uuidString)")

    deinit {
        try? FileManager.default.removeItem(at: blockingFileURL)
    }

    @Test
    func openableStoreIsStoredOnDisk() throws {
        // When
        let sut = AppModelContainer(temporaryStoreID: UUID())

        // Assert
        let configuration = try #require(sut.modelContainer.configurations.first)
        #expect(!configuration.isStoredInMemoryOnly)
    }

    @Test
    func unopenableStoreFallsBackToMemory() throws {
        // Given
        try Data("not a folder".utf8).write(to: blockingFileURL)

        // When
        let sut = AppModelContainer(storeURL: blockingFileURL.appending(path: "MovieApp.store"))

        // Assert
        let configuration = try #require(sut.modelContainer.configurations.first)
        #expect(configuration.isStoredInMemoryOnly)
    }
}
