@testable import MovieApp
import Testing
import UIKit

@MainActor
struct ProfileCoordinatorTests {
    @Test
    func startShowsProfileAsRoot() {
        // Given
        let scenes = SceneFactorySpy()
        let sut = ProfileCoordinator(dependencies: scenes)

        // When
        sut.start()

        // Assert
        #expect(sut.navigationController.viewControllers == [scenes.profile])
    }
}
