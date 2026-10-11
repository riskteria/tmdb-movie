@testable import MovieApp
import Testing

struct ProfileWorkerTests {
    @Test
    func observeThemeStreamsRepositoryChanges() async {
        // Given
        let sut: any IProfileWorker = ProfileWorker(appearanceRepository: AppearanceRepositoryStub(theme: .dark))

        // When
        let stream = await sut.observeTheme()

        // Assert
        #expect(await stream.first { _ in true } == .dark)
    }

    @Test
    func saveThemeForwardsToRepository() async {
        // Given
        let repository = AppearanceRepositoryStub()
        let sut: any IProfileWorker = ProfileWorker(appearanceRepository: repository)

        // When
        await sut.saveTheme(.light)

        // Assert
        #expect(repository.savedThemes == [.light])
    }
}
