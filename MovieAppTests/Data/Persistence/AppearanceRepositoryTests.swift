import Foundation
@testable import MovieApp
import Testing

struct AppearanceRepositoryTests {
    @Test
    func changesStartWithSystemWhenNothingIsStored() async {
        // Given
        let sut: any IAppearanceRepository = AppearanceRepository(suiteName: makeSuiteName())

        // When
        let stream = await sut.changes

        // Assert
        #expect(await stream.first { _ in true } == .system)
    }

    @Test
    func setThemePersistsAcrossInstances() async {
        // Given
        let suiteName = makeSuiteName()
        let sut: any IAppearanceRepository = AppearanceRepository(suiteName: suiteName)

        // When
        await sut.setTheme(.dark)

        // Assert
        let reloaded: any IAppearanceRepository = AppearanceRepository(suiteName: suiteName)
        #expect(await reloaded.changes.first { _ in true } == .dark)
    }
}

private extension AppearanceRepositoryTests {
    func makeSuiteName() -> String {
        "AppearanceRepositoryTests.\(UUID().uuidString)"
    }
}
