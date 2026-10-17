import Foundation
@testable import MovieApp
import Testing

final class KeychainServiceTests {
    private let sut: any IKeychainService = KeychainService(service: "KeychainServiceTests.\(UUID().uuidString)")
    private let key = "item"

    deinit {
        try? sut.removeData(forKey: key)
    }

    @Test
    func dataIsNilWhenMissing() throws {
        // When
        let data = try sut.data(forKey: key)

        // Assert
        #expect(data == nil)
    }

    @Test
    func setDataThenDataReturnsIt() throws {
        // Given
        let stored = Data("first".utf8)

        // When
        try sut.setData(stored, forKey: key)

        // Assert
        #expect(try sut.data(forKey: key) == stored)
    }

    @Test
    func setDataReplacesExistingItem() throws {
        // Given
        try sut.setData(Data("first".utf8), forKey: key)

        // When
        try sut.setData(Data("second".utf8), forKey: key)

        // Assert
        #expect(try sut.data(forKey: key) == Data("second".utf8))
    }

    @Test
    func removeDataDeletesItem() throws {
        // Given
        try sut.setData(Data("first".utf8), forKey: key)

        // When
        try sut.removeData(forKey: key)

        // Assert
        #expect(try sut.data(forKey: key) == nil)
    }

    @Test
    func removeDataOfMissingItemDoesNotThrow() {
        // When & Assert
        #expect(throws: Never.self) {
            try self.sut.removeData(forKey: self.key)
        }
    }
}
