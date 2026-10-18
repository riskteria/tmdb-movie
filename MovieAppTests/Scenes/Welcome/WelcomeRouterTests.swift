@testable import MovieApp
import Testing

@MainActor
struct WelcomeRouterTests {
    private let routes = WelcomeRouteSpy()

    @Test
    func routeToSignInCallsCoordinator() {
        // Given
        let sut = makeSUT()

        // When
        sut.routeToSignIn()

        // Assert
        #expect(routes.recorded == [.signIn])
    }

    @Test
    func routeToGuestCallsCoordinator() {
        // Given
        let sut = makeSUT()

        // When
        sut.routeToGuest()

        // Assert
        #expect(routes.recorded == [.continueAsGuest])
    }
}

private extension WelcomeRouterTests {
    func makeSUT() -> any IWelcomeRouter {
        WelcomeRouter(
            onSignIn: { [routes] in routes.record(.signIn) },
            onContinueAsGuest: { [routes] in routes.record(.continueAsGuest) }
        )
    }
}

private enum WelcomeRoute: Equatable {
    case signIn
    case continueAsGuest
}

@MainActor
private final class WelcomeRouteSpy {
    private(set) var recorded: [WelcomeRoute] = []

    func record(_ route: WelcomeRoute) {
        recorded.append(route)
    }
}
