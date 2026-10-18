protocol IProfileRouter {
    func routeToWelcome(onSignIn: @escaping () -> Void)
    func routeToSignOutConfirmation(_ confirmation: ProfileModel.DisplayedConfirmation, onConfirm: @escaping () -> Void)
}

final class ProfileRouter {
    private let onRequestSignIn: (@escaping () -> Void) -> Void
    private let onRequestSignOut: (ProfileModel.DisplayedConfirmation, @escaping () -> Void) -> Void

    init(
        onRequestSignIn: @escaping (@escaping () -> Void) -> Void,
        onRequestSignOut: @escaping (ProfileModel.DisplayedConfirmation, @escaping () -> Void) -> Void
    ) {
        self.onRequestSignIn = onRequestSignIn
        self.onRequestSignOut = onRequestSignOut
    }
}

// MARK: - IProfileRouter
extension ProfileRouter: IProfileRouter {
    func routeToWelcome(onSignIn: @escaping () -> Void) {
        onRequestSignIn(onSignIn)
    }

    func routeToSignOutConfirmation(_ confirmation: ProfileModel.DisplayedConfirmation, onConfirm: @escaping () -> Void) {
        onRequestSignOut(confirmation, onConfirm)
    }
}
