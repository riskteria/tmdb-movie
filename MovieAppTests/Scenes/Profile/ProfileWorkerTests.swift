@testable import MovieApp
import Testing

struct ProfileWorkerTests {
    private let account = Account(id: 548, username: "moviefan", name: "Movie Fan")

    @Test
    func observeThemeStreamsRepositoryChanges() async {
        // Given
        let sut = makeSUT(appearanceRepository: AppearanceRepositoryStub(theme: .dark))

        // When
        let stream = await sut.observeTheme()

        // Assert
        #expect(await stream.first { _ in true } == .dark)
    }

    @Test
    func saveThemeForwardsToRepository() async {
        // Given
        let repository = AppearanceRepositoryStub()
        let sut = makeSUT(appearanceRepository: repository)

        // When
        await sut.saveTheme(.light)

        // Assert
        #expect(repository.savedThemes == [.light])
    }

    @Test
    func observeAuthStateStreamsRepositoryStates() async {
        // Given
        let sut = makeSUT(authRepository: AuthRepositoryStub(states: [.signedIn(account)]))

        // When
        let stream = await sut.observeAuthState()

        // Assert
        #expect(await stream.first { _ in true } == .signedIn(account))
    }

    @Test
    func signInReturnsRepositoryAccount() async throws {
        // Given
        let ada = Account(id: 7, username: "ada", name: "Ada")
        let sut = makeSUT(authRepository: AuthRepositoryStub(signIn: .success(ada)))

        // When
        let signedInAccount = try await sut.signIn()

        // Assert
        #expect(signedInAccount == ada)
    }

    @Test
    func signOutCallsRepository() async {
        // Given
        let repository = AuthRepositoryStub(states: [.signedIn(account)])
        let sut = makeSUT(authRepository: repository)

        // When
        await sut.signOut()

        // Assert
        #expect(repository.calls == [.signOut])
    }
}

private extension ProfileWorkerTests {
    func makeSUT(
        appearanceRepository: AppearanceRepositoryStub = AppearanceRepositoryStub(),
        authRepository: AuthRepositoryStub = AuthRepositoryStub()
    ) -> any IProfileWorker {
        ProfileWorker(appearanceRepository: appearanceRepository, authRepository: authRepository)
    }
}
