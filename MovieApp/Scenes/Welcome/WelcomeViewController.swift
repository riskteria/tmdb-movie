import UIKit

final class WelcomeViewController: UIViewController {
    private let router: any IWelcomeRouter

    private lazy var welcomeView = WelcomeView()

    init(router: any IWelcomeRouter) {
        self.router = router
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = welcomeView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        welcomeView.configure(
            with: makeContent(),
            signInAction: UIAction { [weak self] _ in self?.signIn() },
            continueAsGuestAction: UIAction { [weak self] _ in self?.continueAsGuest() }
        )
    }
}

private extension WelcomeViewController {
    func signIn() {
        welcomeView.setActionsEnabled(false)
        router.routeToSignIn()
    }

    func continueAsGuest() {
        welcomeView.setActionsEnabled(false)
        router.routeToGuest()
    }

    func makeContent() -> WelcomeModel.DisplayedContent {
        WelcomeModel.DisplayedContent(
            heading: String(localized: "Let's get you signed in"),
            body: String(localized: "Connect your TMDB account. Saved movies and watch history stay on this device."),
            signInTitle: String(localized: "Sign in with TMDB"),
            separatorTitle: String(localized: "or"),
            continueAsGuestTitle: String(localized: "Continue as guest"),
            footnote: String(localized: "You'll approve access on themoviedb.org")
        )
    }
}
