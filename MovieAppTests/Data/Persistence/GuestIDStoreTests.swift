import Foundation
@testable import MovieApp
import Testing

final class GuestIDStoreTests {
    private let suiteName = "GuestIDStoreTests.\(UUID().uuidString)"
    private let otherSuiteName = "GuestIDStoreTests.\(UUID().uuidString)"

    deinit {
        UserDefaults().removePersistentDomain(forName: suiteName)
        UserDefaults().removePersistentDomain(forName: otherSuiteName)
    }

    @Test
    func loadOrCreateReturnsSameIDTwice() {
        // Given
        let firstID = GuestIDStore(suiteName: suiteName).loadOrCreate()

        // When
        let secondID = GuestIDStore(suiteName: suiteName).loadOrCreate()

        // Assert
        #expect(secondID == firstID)
    }

    @Test
    func newSuiteCreatesNewID() {
        // Given
        let firstID = GuestIDStore(suiteName: suiteName).loadOrCreate()

        // When
        let otherID = GuestIDStore(suiteName: otherSuiteName).loadOrCreate()

        // Assert
        #expect(otherID != firstID)
    }
}
