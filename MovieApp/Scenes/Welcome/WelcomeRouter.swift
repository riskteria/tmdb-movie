protocol IWelcomeRouter {
    func routeToSignIn()
    func routeToGuest()
}

final class WelcomeRouter {
    private let onSignIn: () -> Void
    private let onContinueAsGuest: () -> Void

    init(
        onSignIn: @escaping () -> Void,
        onContinueAsGuest: @escaping () -> Void
    ) {
        self.onSignIn = onSignIn
        self.onContinueAsGuest = onContinueAsGuest
    }
}

// MARK: - IWelcomeRouter
extension WelcomeRouter: IWelcomeRouter {
    func routeToSignIn() {
        onSignIn()
    }

    func routeToGuest() {
        onContinueAsGuest()
    }
}
