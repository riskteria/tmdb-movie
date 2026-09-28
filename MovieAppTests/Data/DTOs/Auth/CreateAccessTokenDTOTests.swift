@testable import MovieApp
import Testing

struct CreateAccessTokenDTOTests {
    @Test
    func mapsAccountIDToAccountObjectID() throws {
        // Given
        let json = """
            {
                "account_id": "4bc889XXXXXX",
                "access_token": "user-access-token",
                "success": true,
                "status_message": "Success.",
                "status_code": 1
            }
            """

        // When
        let response = try TMDBJSON.decode(CreateAccessTokenDTO.Response.self, from: json)

        // Assert
        #expect(response.accountObjectID == "4bc889XXXXXX")
        #expect(response.accessToken == "user-access-token")
    }
}
