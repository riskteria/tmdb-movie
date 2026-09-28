@testable import MovieApp
import Testing
import UIKit

@MainActor
struct SearchCoordinatorTests {
    @Test
    func startShowsDiscoverAsRoot() {
        // Given
        let scenes = SceneFactorySpy()
        let sut = SearchCoordinator(dependencies: scenes)

        // When
        sut.start()

        // Assert
        #expect(sut.navigationController.viewControllers == [scenes.discover])
    }
}
