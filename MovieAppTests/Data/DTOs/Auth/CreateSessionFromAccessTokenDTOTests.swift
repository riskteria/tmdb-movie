@testable import MovieApp
import Testing

struct CreateSessionFromAccessTokenDTOTests {
    @Test
    func decodesSessionID() throws {
        // Given
        let json = #"{ "success": true, "session_id": "79191836ddaa0da3df76a5ffef6f07ad6ab0c641" }"#

        // When
        let response = try TMDBJSON.decode(CreateSessionFromAccessTokenDTO.Response.self, from: json)

        // Assert
        #expect(response.sessionID == "79191836ddaa0da3df76a5ffef6f07ad6ab0c641")
        #expect(response.success)
    }
}
