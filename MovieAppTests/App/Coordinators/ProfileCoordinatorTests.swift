@testable import MovieApp
import Testing
import UIKit

@MainActor
struct ProfileCoordinatorTests {
    private let scenes = SceneFactorySpy()
    private let sut: any TabCoordinator & ProfileAlertProvider
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
    func startGivesProfileAConfirmationHandler() {
        // When
        sut.start()

        // Assert
        #expect(scenes.profileConfirmationHandler != nil)
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
    func confirmationAlertShowsConfirmationText() {
        // When
        let alert = sut.makeConfirmationAlert(for: confirmation) {}

        // Assert
        #expect(alert.title == "Sign out of TMDB?")
        #expect(alert.message == "Saved movies and watch history stay on this device.")
    }

    @Test
    func confirmationAlertOffersCancelAndDestructiveAction() {
        // When
        let alert = sut.makeConfirmationAlert(for: confirmation) {}

        // Assert
        #expect(alert.actions.map(\.title) == ["Cancel", "Sign Out"])
        #expect(alert.actions.map(\.style) == [.cancel, .destructive])
    }

    @Test
    func alertHasSingleOKAction() {
        // Given
        let failure = ProfileModel.DisplayedAlert(
            title: "Couldn't clear watch history",
            message: "Nothing was deleted. Try again.",
            actionTitle: "OK"
        )

        // When
        let alert = sut.makeAlert(for: failure)

        // Assert
        #expect(alert.title == "Couldn't clear watch history")
        #expect(alert.actions.map(\.title) == ["OK"])
        #expect(alert.actions.map(\.style) == [.default])
    }
}
