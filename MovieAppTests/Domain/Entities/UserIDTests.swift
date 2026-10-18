import Foundation
@testable import MovieApp
import Testing

struct UserIDTests {
    @Test
    func guestIDHasLocalPrefix() throws {
        // Given
        let guestID = try #require(UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E5F"))

        // When
        let userID = UserID(guestID: guestID)

        // Assert
        #expect(userID.rawValue == "local:e621e1f8-c36c-495a-93fc-0c247a3e6e5f")
    }

    @Test
    func accountIDHasTMDBPrefix() {
        // When
        let userID = UserID(accountID: 42)

        // Assert
        #expect(userID.rawValue == "tmdb:42")
    }
}
