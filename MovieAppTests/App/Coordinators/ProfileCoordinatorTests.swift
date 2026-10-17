@testable import MovieApp
import Testing
import UIKit

@MainActor
struct ProfileCoordinatorTests {
    private let scenes = SceneFactorySpy()
    private let confirmation = ProfileModel.DisplayedConfirmation(
        title: "Sign out of TMDB?",
        message: "Saved movies and watch history stay on this device.",
        confirmTitle: "Sign Out",
        cancelTitle: "Cancel"
    )

    @Test
    func startShowsProfileAsRoot() {
        // Given
        let sut = ProfileCoordinator(dependencies: scenes)

        // When
        sut.start()

        // Assert
        #expect(sut.navigationController.viewControllers == [scenes.profile])
    }

    @Test
    func startGivesProfileASignOutHandler() {
        // Given
        let sut = ProfileCoordinator(dependencies: scenes)

        // When
        sut.start()

        // Assert
        #expect(scenes.profileSignOutHandler != nil)
    }

    @Test
    func signOutAlertShowsConfirmationText() {
        // Given
        let sut = ProfileCoordinator(dependencies: scenes)

        // When
        let alert = sut.makeSignOutAlert(for: confirmation) {}

        // Assert
        #expect(alert.title == "Sign out of TMDB?")
        #expect(alert.message == "Saved movies and watch history stay on this device.")
    }

    @Test
    func signOutAlertOffersCancelAndDestructiveSignOut() {
        // Given
        let sut = ProfileCoordinator(dependencies: scenes)

        // When
        let alert = sut.makeSignOutAlert(for: confirmation) {}

        // Assert
        #expect(alert.actions.map(\.title) == ["Cancel", "Sign Out"])
        #expect(alert.actions.map(\.style) == [.cancel, .destructive])
    }
}
