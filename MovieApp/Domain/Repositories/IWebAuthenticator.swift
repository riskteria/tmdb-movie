import Foundation

@MainActor
protocol IWebAuthenticator: Sendable {
    func authenticate(url: URL, callbackScheme: String) async throws
}
