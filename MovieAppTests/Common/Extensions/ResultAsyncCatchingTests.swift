@testable import MovieApp
import Testing

struct ResultAsyncCatchingTests {
    @Test
    func capturesReturnedValue() async throws {
        // When
        let result = await Result { try await Self.value(7) }

        // Assert
        #expect(try result.get() == 7)
    }

    @Test
    func capturesThrownError() async {
        // When
        let result = await Result { try await Self.failure() }

        // Assert
        #expect(throws: StubError.failed) {
            try result.get()
        }
    }

    private static func value(_ value: Int) async throws -> Int {
        value
    }

    private static func failure() async throws -> Int {
        throw StubError.failed
    }
}
