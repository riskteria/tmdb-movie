import UIKit

enum WelcomeSceneFactory {
    static func make(
        onSignIn: @escaping () -> Void,
        onContinueAsGuest: @escaping () -> Void
    ) -> UIViewController {
        let router = WelcomeRouter(onSignIn: onSignIn, onContinueAsGuest: onContinueAsGuest)
        return WelcomeViewController(router: router)
    }
}
