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
        let sut: any IProfileRouter = ProfileRouter { confirmation, _ in routedConfirmations.append(confirmation) }

        // When
        sut.routeToSignOutConfirmation(confirmation) {}

        // Assert
        #expect(routedConfirmations == [confirmation])
    }

    @Test
    func confirmingRunsTheSignOutAction() {
        // Given
        var signOutCount = 0
        let sut: any IProfileRouter = ProfileRouter { _, onConfirm in onConfirm() }

        // When
        sut.routeToSignOutConfirmation(confirmation) { signOutCount += 1 }

        // Assert
        #expect(signOutCount == 1)
    }
}
