protocol IProfileRouter {
    func routeToSignOutConfirmation(_ confirmation: ProfileModel.DisplayedConfirmation, onConfirm: @escaping () -> Void)
}

final class ProfileRouter {
    private let onRequestSignOut: (ProfileModel.DisplayedConfirmation, @escaping () -> Void) -> Void

    init(onRequestSignOut: @escaping (ProfileModel.DisplayedConfirmation, @escaping () -> Void) -> Void) {
        self.onRequestSignOut = onRequestSignOut
    }
}

// MARK: - IProfileRouter
extension ProfileRouter: IProfileRouter {
    func routeToSignOutConfirmation(_ confirmation: ProfileModel.DisplayedConfirmation, onConfirm: @escaping () -> Void) {
        onRequestSignOut(confirmation, onConfirm)
    }
}
