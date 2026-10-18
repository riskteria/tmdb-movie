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

    @Test
    func routeToSignOutConfirmationPassesConfirmationToCoordinator() {
        // Given
        var routedConfirmations: [ProfileModel.DisplayedConfirmation] = []
        let sut: any IProfileRouter = ProfileRouter(
            onRequestSignIn: { _ in },
            onRequestSignOut: { confirmation, _ in routedConfirmations.append(confirmation) }
        )

        // When
        sut.routeToSignOutConfirmation(confirmation) {}

        // Assert
        #expect(routedConfirmations == [confirmation])
    }

    @Test
    func confirmingRunsTheSignOutAction() {
        // Given
        var signOutCount = 0
        let sut: any IProfileRouter = ProfileRouter(
            onRequestSignIn: { _ in },
            onRequestSignOut: { _, onConfirm in onConfirm() }
        )

        // When
        sut.routeToSignOutConfirmation(confirmation) { signOutCount += 1 }

        // Assert
        #expect(signOutCount == 1)
    }

    @Test
    func routeToWelcomePassesSignInToCoordinator() {
        // Given
        var signInCount = 0
        let sut: any IProfileRouter = ProfileRouter(
            onRequestSignIn: { onSignIn in onSignIn() },
            onRequestSignOut: { _, _ in }
        )

        // When
        sut.routeToWelcome { signInCount += 1 }

        // Assert
        #expect(signInCount == 1)
    }
}
