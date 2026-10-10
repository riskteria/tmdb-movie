@testable import MovieApp
import Testing

@MainActor
struct ProfileInteractorTests {
    @Test
    func loadProfilePresentsAppInfo() throws {
        // Given
        let presenter = ProfilePresenterSpy()
        let appInfo = AppInfo(version: "1.0", build: "7")
        let sut: any IProfileInteractor = ProfileInteractor(presenter: presenter, appInfo: appInfo)

        // When
        sut.loadProfile(request: ProfileModel.LoadProfile.Request())

        // Assert
        let response = try #require(presenter.responses.first)
        #expect(response.appInfo == appInfo)
    }
}

@MainActor
private final class ProfilePresenterSpy: IProfilePresenter {
    private(set) var responses: [ProfileModel.LoadProfile.Response] = []

    func presentProfile(response: ProfileModel.LoadProfile.Response) {
        responses.append(response)
    }
}
