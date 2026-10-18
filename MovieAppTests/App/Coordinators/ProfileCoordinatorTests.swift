@testable import MovieApp
import Testing
import UIKit

@MainActor
struct ProfileCoordinatorTests {
    private let scenes = SceneFactorySpy()
    private let sut: any TabCoordinator & SignOutAlertProvider
    private let confirmation = ProfileModel.DisplayedConfirmation(
        title: "Sign out of TMDB?",
        message: "Saved movies and watch history stay on this device.",
        confirmTitle: "Sign Out",
        cancelTitle: "Cancel"
    )

    init() {
        sut = ProfileCoordinator(dependencies: scenes)
    }

    @Test
    func startShowsProfileAsRoot() {
        // When
        sut.start()

        // Assert
        #expect(sut.navigationController.viewControllers == [scenes.profile])
    }

    @Test
    func startGivesProfileASignInHandler() {
        // When
        sut.start()

        // Assert
        #expect(scenes.profileSignInHandler != nil)
    }

    @Test
    func startGivesProfileASignOutHandler() {
        // When
        sut.start()

        // Assert
        #expect(scenes.profileSignOutHandler != nil)
    }

    @Test
    func signInRequestBuildsWelcome() throws {
        // Given
        sut.start()
        let requestSignIn = try #require(scenes.profileSignInHandler)

        // When
        requestSignIn {}

        // Assert
        #expect(scenes.welcomeRequestCount == 1)
    }

    @Test
    func signOutAlertShowsConfirmationText() {
        // When
        let alert = sut.makeSignOutAlert(for: confirmation) {}

        // Assert
        #expect(alert.title == "Sign out of TMDB?")
        #expect(alert.message == "Saved movies and watch history stay on this device.")
    }

    @Test
    func signOutAlertOffersCancelAndDestructiveSignOut() {
        // When
        let alert = sut.makeSignOutAlert(for: confirmation) {}

        // Assert
        #expect(alert.actions.map(\.title) == ["Cancel", "Sign Out"])
        #expect(alert.actions.map(\.style) == [.cancel, .destructive])
    }
}
