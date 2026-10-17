import Foundation
import Networking

nonisolated protocol ISessionService: Sendable {
    func createSession() async throws -> AuthSession
    func revokeSession(_ authSession: AuthSession) async
}

nonisolated struct SessionService {
    private let apiService: any IAPIService
    private let webAuthenticator: any IWebAuthenticator
    private let callbackScheme = "movieapp"
    private let approvalPage = "https://www.themoviedb.org/auth/access"

    init(apiService: any IAPIService, webAuthenticator: any IWebAuthenticator) {
        self.apiService = apiService
        self.webAuthenticator = webAuthenticator
    }
}

// MARK: - ISessionService
nonisolated extension SessionService: ISessionService {
    func createSession() async throws -> AuthSession {
        let requestToken: CreateRequestTokenDTO.Response = try await apiService.request(
            .createRequestToken(request: .init(redirectTo: "\(callbackScheme)://auth"))
        )
        try await webAuthenticator.authenticate(
            url: makeApprovalURL(for: requestToken.requestToken),
            callbackScheme: callbackScheme
        )
        let accessToken: CreateAccessTokenDTO.Response = try await apiService.request(
            .createAccessToken(request: .init(requestToken: requestToken.requestToken))
        )
        let session: CreateSessionFromAccessTokenDTO.Response = try await apiService.request(
            .createSessionFromAccessToken(request: .init(accessToken: accessToken.accessToken))
        )
        let details: AccountDetailsDTO.Response = try await apiService.request(
            .accountDetails(parameters: .init(sessionID: session.sessionID))
        )
        return AuthSession(
            accessToken: accessToken.accessToken,
            accountObjectID: accessToken.accountObjectID,
            sessionID: session.sessionID,
            accountID: details.id,
            username: details.username,
            name: details.name
        )
    }

    func revokeSession(_ authSession: AuthSession) async {
        async let revokedToken: DeleteAccessTokenDTO.Response? = try? apiService.request(
            .deleteAccessToken(request: .init(accessToken: authSession.accessToken))
        )
        async let deletedSession: DeleteSessionDTO.Response? = try? apiService.request(
            .deleteSession(request: .init(sessionID: authSession.sessionID))
        )
        _ = await (revokedToken, deletedSession)
    }
}

private nonisolated extension SessionService {
    func makeApprovalURL(for requestToken: String) throws -> URL {
        var components = URLComponents(string: approvalPage)
        components?.queryItems = [URLQueryItem(name: "request_token", value: requestToken)]
        guard let url = components?.url else { throw NetworkError.requestFailed }
        return url
    }
}
