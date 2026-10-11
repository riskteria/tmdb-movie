@testable import MovieApp
import Synchronization
import Testing

@MainActor
struct ProfileInteractorTests {
    private let presenter = ProfilePresenterSpy()
    private let appInfo = AppInfo(version: "1.0", build: "7")

    @Test
    func loadProfilePresentsAppInfo() async throws {
        // Given
        let sut: any IProfileInteractor = ProfileInteractor(
            presenter: presenter,
            worker: ProfileWorkerStub(),
            appInfo: appInfo
        )

        // When
        await sut.loadProfile(request: ProfileModel.LoadProfile.Request())

        // Assert
        let response = try #require(presenter.responses.first)
        #expect(response.appInfo == appInfo)
    }

    @Test
    func loadProfilePresentsStoredTheme() async throws {
        // Given
        let sut: any IProfileInteractor = ProfileInteractor(
            presenter: presenter,
            worker: ProfileWorkerStub(theme: .dark),
            appInfo: appInfo
        )

        // When
        await sut.loadProfile(request: ProfileModel.LoadProfile.Request())

        // Assert
        let response = try #require(presenter.responses.first)
        #expect(response.theme == .dark)
    }

    @Test
    func changeAppearanceSavesSelectedTheme() async {
        // Given
        let worker = ProfileWorkerStub()
        let sut: any IProfileInteractor = ProfileInteractor(presenter: presenter, worker: worker, appInfo: appInfo)

        // When
        await sut.changeAppearance(request: ProfileModel.ChangeAppearance.Request(theme: .light))

        // Assert
        #expect(worker.savedThemes == [.light])
    }
}

@MainActor
private final class ProfilePresenterSpy: IProfilePresenter {
    private(set) var responses: [ProfileModel.LoadProfile.Response] = []

    func presentProfile(response: ProfileModel.LoadProfile.Response) {
        responses.append(response)
    }
}

private final class ProfileWorkerStub: IProfileWorker {
    private let theme: AppTheme
    private let recordedThemes = Mutex<[AppTheme]>([])

    var savedThemes: [AppTheme] {
        recordedThemes.withLock { $0 }
    }

    init(theme: AppTheme = .system) {
        self.theme = theme
    }

    func observeTheme() async -> AsyncStream<AppTheme> {
        AsyncStream { continuation in
            continuation.yield(theme)
            continuation.finish()
        }
    }

    func saveTheme(_ theme: AppTheme) async {
        recordedThemes.withLock { $0.append(theme) }
    }
}
