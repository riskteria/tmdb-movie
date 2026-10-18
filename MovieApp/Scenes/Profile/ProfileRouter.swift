protocol IProfileRouter {
    func routeToWelcome(onSignIn: @escaping () -> Void)
    func routeToConfirmation(_ confirmation: ProfileModel.DisplayedConfirmation, onConfirm: @escaping () -> Void)
    func routeToAlert(_ alert: ProfileModel.DisplayedAlert)
}

final class ProfileRouter {
    private let onRequestSignIn: (@escaping () -> Void) -> Void
    private let onRequestConfirmation: (ProfileModel.DisplayedConfirmation, @escaping () -> Void) -> Void
    private let onShowAlert: (ProfileModel.DisplayedAlert) -> Void

    init(
        onRequestSignIn: @escaping (@escaping () -> Void) -> Void,
        onRequestConfirmation: @escaping (ProfileModel.DisplayedConfirmation, @escaping () -> Void) -> Void,
        onShowAlert: @escaping (ProfileModel.DisplayedAlert) -> Void
    ) {
        self.onRequestSignIn = onRequestSignIn
        self.onRequestConfirmation = onRequestConfirmation
        self.onShowAlert = onShowAlert
    }
}

// MARK: - IProfileRouter
extension ProfileRouter: IProfileRouter {
    func routeToWelcome(onSignIn: @escaping () -> Void) {
        onRequestSignIn(onSignIn)
    }

    func routeToConfirmation(_ confirmation: ProfileModel.DisplayedConfirmation, onConfirm: @escaping () -> Void) {
        onRequestConfirmation(confirmation, onConfirm)
    }

    func routeToAlert(_ alert: ProfileModel.DisplayedAlert) {
        onShowAlert(alert)
    }
}
