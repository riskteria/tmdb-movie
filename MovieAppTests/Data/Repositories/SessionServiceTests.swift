import Foundation
@testable import MovieApp
@testable import Networking
import Synchronization
import Testing

@MainActor
struct SessionServiceTests {
    private let createRequestToken = TMDBEndpoint.createRequestToken(request: .init(redirectTo: "movieapp://auth"))
    private let createAccessToken = TMDBEndpoint.createAccessToken(request: .init(requestToken: "request-token"))
    private let createSession = TMDBEndpoint.createSessionFromAccessToken(request: .init(accessToken: "access-token"))
    private let accountDetails = TMDBEndpoint.accountDetails(parameters: .init(sessionID: "session"))
    private let revokeRoutes: Set<String> = ["DELETE /4/auth/access_token", "DELETE /3/authentication/session"]
    private let authSession = AuthSession(
        accessToken: "access-token",
        accountObjectID: "4bc889",
        sessionID: "session",
        accountID: 548,
        username: "moviefan",
        name: "Movie Fan"
    )

    @Test
    func createSessionMapsAllFourResponses() async throws {
        // Given
        let sut = makeSUT(apiService: try makeSignInAPIService())

        // When
        let session = try await sut.createSession()

        // Assert
        #expect(session == authSession)
    }

    @Test
    func createSessionOpensApprovalURLWithRequestToken() async throws {
        // Given
        let webAuthenticator = WebAuthenticatorStub()
        let sut = makeSUT(apiService: try makeSignInAPIService(), webAuthenticator: webAuthenticator)

        // When
        _ = try await sut.createSession()

        // Assert
        let approvalURL = try #require(URL(string: "https://www.themoviedb.org/auth/access?request_token=request-token"))
        #expect(webAuthenticator.authentications == [Authentication(url: approvalURL, callbackScheme: "movieapp")])
    }

    @Test
    func createSessionThrowsCancellationWhenSheetClosed() async throws {
        // Given
        let sut = makeSUT(
            apiService: try makeSignInAPIService(),
            webAuthenticator: WebAuthenticatorStub(result: .failure(CancellationError()))
        )

        // When & Assert
        await #expect(throws: CancellationError.self) {
            try await sut.createSession()
        }
    }

    @Test
    func cancelledSheetRequestsNoAccessToken() async throws {
        // Given
        let apiService = try makeSignInAPIService()
        let sut = makeSUT(
            apiService: apiService,
            webAuthenticator: WebAuthenticatorStub(result: .failure(CancellationError()))
        )

        // When
        _ = try? await sut.createSession()

        // Assert
        #expect(apiService.requestedRoutes == ["POST /4/auth/request_token"])
    }

    @Test
    func createSessionThrowsWhenSessionStepFails() async throws {
        // Given
        let apiService = try makeSignInAPIService(
            createSessionResult: .failure(NetworkError.invalidResponse(statusCode: 401))
        )
        let sut = makeSUT(apiService: apiService)

        // When & Assert
        await #expect(throws: NetworkError.invalidResponse(statusCode: 401)) {
            try await sut.createSession()
        }
    }

    @Test
    func revokeSessionDeletesTokenAndSession() async throws {
        // Given
        let apiService = try makeRevokeAPIService(
            result: .success(#"{ "success": true, "status_code": 13, "status_message": "Deleted." }"#)
        )
        let sut = makeSUT(apiService: apiService)

        // When
        await sut.revokeSession(authSession)

        // Assert
        #expect(Set(apiService.requestedRoutes) == revokeRoutes)
    }

    @Test
    func revokeSessionIgnoresFailures() async throws {
        // Given
        let apiService = try makeRevokeAPIService(result: .failure(StubError.failed))
        let sut = makeSUT(apiService: apiService)

        // When
        await sut.revokeSession(authSession)

        // Assert
        #expect(Set(apiService.requestedRoutes) == revokeRoutes)
    }
}

private extension SessionServiceTests {
    func makeSUT(
        apiService: MultiResponseAPIServiceStub,
        webAuthenticator: WebAuthenticatorStub = WebAuthenticatorStub()
    ) -> any ISessionService {
        SessionService(apiService: apiService, webAuthenticator: webAuthenticator)
    }

    func makeSignInAPIService(
        createSessionResult: Result<String, any Error>? = nil
    ) throws -> MultiResponseAPIServiceStub {
        MultiResponseAPIServiceStub(responses: [
            try CannedResponse(createRequestToken, .success(JSONFixture.named(.createRequestToken))),
            try CannedResponse(createAccessToken, .success(JSONFixture.named(.createAccessToken))),
            try CannedResponse(createSession, createSessionResult ?? .success(JSONFixture.named(.createSession))),
            try CannedResponse(accountDetails, .success(JSONFixture.named(.accountDetails)))
        ])
    }

    func makeRevokeAPIService(result: Result<String, any Error>) throws -> MultiResponseAPIServiceStub {
        MultiResponseAPIServiceStub(responses: [
            try CannedResponse(.deleteAccessToken(request: .init(accessToken: "access-token")), result),
            try CannedResponse(.deleteSession(request: .init(sessionID: "session")), result)
        ])
    }
}

private struct CannedResponse {
    let request: URLRequest
    let result: Result<String, any Error>

    init(_ endpoint: TMDBEndpoint, _ result: Result<String, any Error>) throws {
        request = try endpoint.asURLRequest()
        self.result = result
    }
}

private final class MultiResponseAPIServiceStub: IAPIService {
    private let responses: [CannedResponse]
    private let requests = Mutex<[URLRequest]>([])

    var requestedRoutes: [String] {
        requests.withLock { requests in
            requests.map { request in "\(request.httpMethod ?? "") \(request.url?.path() ?? "")" }
        }
    }

    init(responses: [CannedResponse]) {
        self.responses = responses
    }

    func request<Response: Decodable & Sendable>(_ endpoint: TMDBEndpoint) async throws -> Response {
        let request = try endpoint.asURLRequest()
        requests.withLock { $0.append(request) }
        let response = try #require(
            responses.first { response in response.request == request },
            "Unexpected request: \(request.httpMethod ?? "") \(request.url?.absoluteString ?? "")"
        )
        return try TMDBJSON.decode(Response.self, from: response.result.get())
    }
}

private struct Authentication: Equatable {
    let url: URL
    let callbackScheme: String
}

@MainActor
private final class WebAuthenticatorStub: IWebAuthenticator {
    private let result: Result<Void, any Error>
    private(set) var authentications: [Authentication] = []

    init(result: Result<Void, any Error> = .success(())) {
        self.result = result
    }

    func authenticate(url: URL, callbackScheme: String) async throws {
        authentications.append(Authentication(url: url, callbackScheme: callbackScheme))
        try result.get()
    }
}
