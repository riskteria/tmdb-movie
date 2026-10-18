@testable import MovieApp
import Testing

@MainActor
struct ProfileInteractorTests {
    private let presenter = ProfilePresenterSpy()
    private let appInfo = AppInfo(version: "1.0", build: "7")
    private let account = Account(id: 548, username: "moviefan", name: "Movie Fan", avatarPath: nil)

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

    @Test
    func loadProfileRefreshesAccountOnce() async {
        // Given
        let worker = ProfileWorkerStub(authStates: makeFinishedStream([.signedIn(account)]))
        let sut = makeSUT(worker: worker)

        // When
        await sut.loadProfile(request: ProfileModel.LoadProfile.Request())

        // Assert
        #expect(worker.refreshAccountCount == 1)
    }

    @Test
    func storedAccountShownBeforeRefreshFinishes() async throws {
        // Given
        let (refreshGate, refreshRelease) = AsyncStream.makeStream(of: Void.self)
        let worker = ProfileWorkerStub(authStates: makeFinishedStream([.signedIn(account)]), refreshGate: refreshGate)
        let sut = makeSUT(worker: worker)
        let loadProfile = Task { await sut.loadProfile(request: ProfileModel.LoadProfile.Request()) }

        // When
        await presenter.waitForFirstResponse()

        // Assert
        let response = try #require(presenter.responses.first)
        #expect(response.accountState == .signedIn(account))
        refreshRelease.finish()
        await loadProfile.value
    }

    @Test
    func sessionEndedPresentsSessionEnded() async throws {
        // Given
        let worker = ProfileWorkerStub(
            authStates: makeFinishedStream([.signedIn(account), .signedOut]),
            refreshAccount: .sessionEnded
        )
        let sut = makeSUT(worker: worker)

        // When
        await sut.loadProfile(request: ProfileModel.LoadProfile.Request())

        // Assert
        let response = try #require(presenter.responses.last)
        #expect(response.accountState == .sessionEnded)
    }

    @Test
    func sessionEndedSurvivesSignedOutBroadcast() async throws {
        // Given
        let (authStates, authContinuation) = AsyncStream.makeStream(of: AuthState.self)
        authContinuation.yield(.signedIn(account))
        let sut = makeSUT(worker: ProfileWorkerStub(authStates: authStates, refreshAccount: .sessionEnded))
        let loadProfile = Task { await sut.loadProfile(request: ProfileModel.LoadProfile.Request()) }
        await presenter.waitForResponse { response in response.accountState == .sessionEnded }

        // When
        authContinuation.yield(.signedOut)
        authContinuation.finish()
        await loadProfile.value

        // Assert
        let response = try #require(presenter.responses.last)
        #expect(response.accountState == .sessionEnded)
    }

    @Test
    func signInAfterSessionEndedPresentsPending() async {
        // Given
        let worker = ProfileWorkerStub(
            authStates: makeFinishedStream([.signedIn(account), .signedOut]),
            signIn: .failure(CancellationError()),
            refreshAccount: .sessionEnded
        )
        let sut = makeSUT(worker: worker)
        await sut.loadProfile(request: ProfileModel.LoadProfile.Request())

        // When
        await sut.signIn(request: ProfileModel.SignIn.Request())

        // Assert
        #expect(presenter.responses.suffix(2).map(\.accountState) == [.signInPending, .guest])
    }

    @Test
    func clearSavedDataPresentsNothingOnSuccess() async {
        // Given
        let worker = ProfileWorkerStub()
        let sut = makeSUT(worker: worker)

        // When
        await sut.clearSavedData(request: ProfileModel.ClearSavedData.Request())

        // Assert
        #expect(worker.clearCalls == [.savedMovies])
        #expect(presenter.clearSavedDataCount == 0)
    }

    @Test
    func clearSavedDataPresentsFailure() async {
        // Given
        let sut = makeSUT(worker: ProfileWorkerStub(clearSavedMovies: .failure(StubError.failed)))

        // When
        await sut.clearSavedData(request: ProfileModel.ClearSavedData.Request())

        // Assert
        #expect(presenter.clearSavedDataCount == 1)
    }

    @Test
    func clearWatchHistoryPresentsNothingOnSuccess() async {
        // Given
        let worker = ProfileWorkerStub()
        let sut = makeSUT(worker: worker)

        // When
        await sut.clearWatchHistory(request: ProfileModel.ClearWatchHistory.Request())

        // Assert
        #expect(worker.clearCalls == [.watchHistory])
        #expect(presenter.clearWatchHistoryCount == 0)
    }

    @Test
    func clearWatchHistoryPresentsFailure() async {
        // Given
        let sut = makeSUT(worker: ProfileWorkerStub(clearWatchHistory: .failure(StubError.failed)))

        // When
        await sut.clearWatchHistory(request: ProfileModel.ClearWatchHistory.Request())

        // Assert
        #expect(presenter.clearWatchHistoryCount == 1)
    }

    @Test
    func unchangedRefreshKeepsAccountState() async throws {
        // Given
        let worker = ProfileWorkerStub(authStates: makeFinishedStream([.signedIn(account)]), refreshAccount: .unchanged)
        let sut = makeSUT(worker: worker)

        // When
        await sut.loadProfile(request: ProfileModel.LoadProfile.Request())

        // Assert
        let response = try #require(presenter.responses.last)
        #expect(response.accountState == .signedIn(account))
    }
}

private extension ProfileInteractorTests {
    func makeSUT(worker: ProfileWorkerStub = ProfileWorkerStub()) -> any IProfileInteractor {
        ProfileInteractor(presenter: presenter, worker: worker, appInfo: appInfo)
    }

    func makeFinishedStream<Element: Sendable>(_ elements: [Element]) -> AsyncStream<Element> {
        AsyncStream { continuation in
            elements.forEach { element in continuation.yield(element) }
            continuation.finish()
        }
    }
}

@MainActor
private final class ProfilePresenterSpy: IProfilePresenter {
    private(set) var responses: [ProfileModel.LoadProfile.Response] = []
    private var responseWaiters: [ResponseWaiter] = []
    private(set) var clearSavedDataCount = 0
    private(set) var clearWatchHistoryCount = 0

    func presentProfile(response: ProfileModel.LoadProfile.Response) {
        responses.append(response)
        let matching = responseWaiters.filter { waiter in waiter.isMatch(response) }
        responseWaiters.removeAll { waiter in waiter.isMatch(response) }
        matching.forEach { waiter in waiter.continuation.resume() }
    }

    func presentClearSavedData(response: ProfileModel.ClearSavedData.Response) {
        clearSavedDataCount += 1
    }

    func presentClearWatchHistory(response: ProfileModel.ClearWatchHistory.Response) {
        clearWatchHistoryCount += 1
    }

    func waitForFirstResponse() async {
        await waitForResponse { _ in true }
    }

    func waitForResponse(where isMatch: @escaping (ProfileModel.LoadProfile.Response) -> Bool) async {
        guard !responses.contains(where: isMatch) else { return }
        await withCheckedContinuation { continuation in
            responseWaiters.append(ResponseWaiter(isMatch: isMatch, continuation: continuation))
        }
    }
}

@MainActor
private struct ResponseWaiter {
    let isMatch: (ProfileModel.LoadProfile.Response) -> Bool
    let continuation: CheckedContinuation<Void, Never>
}
