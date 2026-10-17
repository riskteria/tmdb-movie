import AuthenticationServices
import UIKit

final class WebAuthenticator {
    private weak var window: UIWindow?
    private var session: ASWebAuthenticationSession?
    private var presentationContext: PresentationContext?

    init(window: UIWindow) {
        self.window = window
    }
}

// MARK: - IWebAuthenticator
extension WebAuthenticator: IWebAuthenticator {
    func authenticate(url: URL, callbackScheme: String) async throws {
        guard let window else { throw ASWebAuthenticationSessionError(.presentationContextNotProvided) }
        let presentationContext = PresentationContext(anchor: window)
        self.presentationContext = presentationContext
        defer {
            session = nil
            self.presentationContext = nil
        }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
            let session = ASWebAuthenticationSession(
                url: url,
                callback: .customScheme(callbackScheme)
            ) { @Sendable _, error in
                guard let error else {
                    continuation.resume()
                    return
                }
                let isCancelled = (error as? ASWebAuthenticationSessionError)?.code == .canceledLogin
                continuation.resume(throwing: isCancelled ? CancellationError() : error)
            }
            session.presentationContextProvider = presentationContext
            session.prefersEphemeralWebBrowserSession = true
            if session.canStart {
                self.session = session
                _ = session.start()
            } else {
                continuation.resume(throwing: ASWebAuthenticationSessionError(.presentationContextInvalid))
            }
        }
    }
}

private final class PresentationContext: NSObject {
    private let anchor: ASPresentationAnchor

    init(anchor: ASPresentationAnchor) {
        self.anchor = anchor
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding
extension PresentationContext: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        anchor
    }
}
