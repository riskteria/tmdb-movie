@testable import MovieApp
import Testing

@MainActor
struct ProfileRouterTests {
    private let confirmation = ProfileModel.DisplayedConfirmation(
        title: "Sign out of TMDB?",
        message: "Saved movies and watch history stay on this device.",
        confirmTitle: "Sign Out",
        cancelTitle: "Cancel"
    )
    private let alert = ProfileModel.DisplayedAlert(
        title: "Couldn't clear Saved data",
        message: "Nothing was deleted. Try again.",
        actionTitle: "OK"
    )

    @Test
    func routeToConfirmationPassesConfirmation() {
        // Given
        var routedConfirmations: [ProfileModel.DisplayedConfirmation] = []
        let sut: any IProfileRouter = ProfileRouter(
            onRequestSignIn: { _ in },
            onRequestConfirmation: { confirmation, _ in routedConfirmations.append(confirmation) },
            onShowAlert: { _ in }
        )

        // When
        sut.routeToConfirmation(confirmation) {}

        // Assert
        #expect(routedConfirmations == [confirmation])
    }

    @Test
    func confirmingRunsTheConfirmedAction() {
        // Given
        var confirmCount = 0
        let sut: any IProfileRouter = ProfileRouter(
            onRequestSignIn: { _ in },
            onRequestConfirmation: { _, onConfirm in onConfirm() },
            onShowAlert: { _ in }
        )

        // When
        sut.routeToConfirmation(confirmation) { confirmCount += 1 }

        // Assert
        #expect(confirmCount == 1)
    }

    @Test
    func routeToAlertPassesAlert() {
        // Given
        var routedAlerts: [ProfileModel.DisplayedAlert] = []
        let sut: any IProfileRouter = ProfileRouter(
            onRequestSignIn: { _ in },
            onRequestConfirmation: { _, _ in },
            onShowAlert: { alert in routedAlerts.append(alert) }
        )

        // When
        sut.routeToAlert(alert)

        // Assert
        #expect(routedAlerts == [alert])
    }

    @Test
    func routeToWelcomePassesSignInToCoordinator() {
        // Given
        var signInCount = 0
        let sut: any IProfileRouter = ProfileRouter(
            onRequestSignIn: { onSignIn in onSignIn() },
            onRequestConfirmation: { _, _ in },
            onShowAlert: { _ in }
        )

        // When
        sut.routeToWelcome { signInCount += 1 }

        // Assert
        #expect(signInCount == 1)
    }
}
