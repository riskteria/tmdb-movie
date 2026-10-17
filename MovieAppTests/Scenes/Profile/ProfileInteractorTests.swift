@testable import MovieApp
import Synchronization
import Testing

@MainActor
struct ProfileInteractorTests {
    private let presenter = ProfilePresenterSpy()
    private let appInfo = AppInfo(version: "1.0", build: "7")
    private let account = Account(id: 548, username: "moviefan", name: "Movie Fan")

    @Test
    func loadProfilePresentsAppInfo() async throws {
        // Given
        let sut = makeSUT()

        // When
        await sut.loadProfile(request: ProfileModel.LoadProfile.Request())

        // Assert
        let response = try #require(presenter.responses.first)
        #expect(response.appInfo == appInfo)
    }

    @Test
    func loadProfilePresentsStoredTheme() async throws {
        // Given
        let sut = makeSUT(worker: ProfileWorkerStub(themes: makeFinishedStream([.dark])))

        // When
        await sut.loadProfile(request: ProfileModel.LoadProfile.Request())

        // Assert
        let response = try #require(presenter.responses.first)
        #expect(response.theme == .dark)
    }

    @Test
    func loadProfileWaitsForThemeAndAuthState() async {
        // Given
        let sut = makeSUT(worker: ProfileWorkerStub(authStates: makeFinishedStream([])))

        // When
        await sut.loadProfile(request: ProfileModel.LoadProfile.Request())

        // Assert
        #expect(presenter.responses.isEmpty)
    }

    @Test
    func signedInStatePresentsAccount() async throws {
        // Given
        let sut = makeSUT(worker: ProfileWorkerStub(authStates: makeFinishedStream([.signedIn(account)])))

        // When
        await sut.loadProfile(request: ProfileModel.LoadProfile.Request())

        // Assert
        let response = try #require(presenter.responses.last)
        #expect(response.accountState == .signedIn(account))
    }

    @Test
    func signedOutStatePresentsGuest() async throws {
        // Given
        let sut = makeSUT()

        // When
        await sut.loadProfile(request: ProfileModel.LoadProfile.Request())

        // Assert
        let response = try #require(presenter.responses.last)
        #expect(response.accountState == .guest)
    }

    @Test
    func themeChangeKeepsAccountState() async {
        // Given
        let (themes, themeContinuation) = AsyncStream.makeStream(of: AppTheme.self)
        themeContinuation.yield(.system)
        let worker = ProfileWorkerStub(themes: themes, authStates: makeFinishedStream([.signedIn(account)]))
        let sut = makeSUT(worker: worker)
        let loadProfile = Task { await sut.loadProfile(request: ProfileModel.LoadProfile.Request()) }
        await presenter.waitForFirstResponse()

        // When
        themeContinuation.yield(.dark)
        themeContinuation.finish()
        await loadProfile.value

        // Assert
        #expect(presenter.responses.map(\.accountState) == [.signedIn(account), .signedIn(account)])
    }

    @Test
    func signInPresentsPendingThenSignedIn() async {
        // Given
        let sut = makeSUT(worker: ProfileWorkerStub(signIn: .success(account)))
        await sut.loadProfile(request: ProfileModel.LoadProfile.Request())

        // When
        await sut.signIn(request: ProfileModel.SignIn.Request())

        // Assert
        #expect(presenter.responses.map(\.accountState) == [.guest, .signInPending, .signedIn(account)])
    }

    @Test
    func cancelledSignInPresentsGuest() async throws {
        // Given
        let sut = makeSUT(worker: ProfileWorkerStub(signIn: .failure(CancellationError())))
        await sut.loadProfile(request: ProfileModel.LoadProfile.Request())

        // When
        await sut.signIn(request: ProfileModel.SignIn.Request())

        // Assert
        let response = try #require(presenter.responses.last)
        #expect(response.accountState == .guest)
    }

    @Test
    func failedSignInPresentsFailure() async throws {
        // Given
        let sut = makeSUT(worker: ProfileWorkerStub(signIn: .failure(StubError.failed)))
        await sut.loadProfile(request: ProfileModel.LoadProfile.Request())

        // When
        await sut.signIn(request: ProfileModel.SignIn.Request())

        // Assert
        let response = try #require(presenter.responses.last)
        #expect(response.accountState == .signInFailed)
    }

    @Test
    func signOutPresentsNothingItself() async {
        // Given
        let sut = makeSUT(worker: ProfileWorkerStub(authStates: makeFinishedStream([.signedIn(account)])))
        await sut.loadProfile(request: ProfileModel.LoadProfile.Request())

        // When
        await sut.signOut(request: ProfileModel.SignOut.Request())

        // Assert
        #expect(presenter.responses.count == 1)
    }

    @Test
    func signOutForwardsToWorker() async {
        // Given
        let worker = ProfileWorkerStub(authStates: makeFinishedStream([.signedIn(account)]))
        let sut = makeSUT(worker: worker)

        // When
        await sut.signOut(request: ProfileModel.SignOut.Request())

        // Assert
        #expect(worker.signOutCount == 1)
    }

    @Test
    func changeAppearanceSavesSelectedTheme() async {
        // Given
        let worker = ProfileWorkerStub()
        let sut = makeSUT(worker: worker)

        // When
        await sut.changeAppearance(request: ProfileModel.ChangeAppearance.Request(theme: .light))

        // Assert
        #expect(worker.savedThemes == [.light])
    }
}

private extension ProfileInteractorTests {
    func makeSUT(worker: ProfileWorkerStub = ProfileWorkerStub()) -> any IProfileInteractor {
        ProfileInteractor(presenter: presenter, worker: worker, appInfo: appInfo)
    }
}

@MainActor
private final class ProfilePresenterSpy: IProfilePresenter {
    private(set) var responses: [ProfileModel.LoadProfile.Response] = []
    private var responseWaiters: [CheckedContinuation<Void, Never>] = []

    func presentProfile(response: ProfileModel.LoadProfile.Response) {
        responses.append(response)
        responseWaiters.forEach { $0.resume() }
        responseWaiters.removeAll()
    }

    func waitForFirstResponse() async {
        guard responses.isEmpty else { return }
        await withCheckedContinuation { responseWaiters.append($0) }
    }
}

private final class ProfileWorkerStub: IProfileWorker {
    private let themes: AsyncStream<AppTheme>
    private let authStates: AsyncStream<AuthState>
    private let signInResult: Result<Account, any Error>
    private let recordedThemes = Mutex<[AppTheme]>([])
    private let recordedSignOuts = Mutex(0)

    var savedThemes: [AppTheme] {
        recordedThemes.withLock { $0 }
    }

    var signOutCount: Int {
        recordedSignOuts.withLock { $0 }
    }

    init(
        themes: AsyncStream<AppTheme> = makeFinishedStream([.system]),
        authStates: AsyncStream<AuthState> = makeFinishedStream([.signedOut]),
        signIn: Result<Account, any Error> = .success(Account(id: 548, username: "moviefan", name: "Movie Fan"))
    ) {
        self.themes = themes
        self.authStates = authStates
        signInResult = signIn
    }

    func observeTheme() async -> AsyncStream<AppTheme> {
        themes
    }

    func saveTheme(_ theme: AppTheme) async {
        recordedThemes.withLock { $0.append(theme) }
    }

    func observeAuthState() async -> AsyncStream<AuthState> {
        authStates
    }

    func signIn() async throws -> Account {
        try signInResult.get()
    }

    func signOut() async {
        recordedSignOuts.withLock { $0 += 1 }
    }
}

private func makeFinishedStream<Element>(_ elements: [Element]) -> AsyncStream<Element> {
    AsyncStream { continuation in
        elements.forEach { element in continuation.yield(element) }
        continuation.finish()
    }
}
