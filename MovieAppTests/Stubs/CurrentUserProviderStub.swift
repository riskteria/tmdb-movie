@testable import MovieApp

final class CurrentUserProviderStub: CurrentUserProvider {
    private let stream: AsyncStream<UserID>
    private let continuation: AsyncStream<UserID>.Continuation

    var userIDs: AsyncStream<UserID> {
        get async {
            stream
        }
    }

    init(userID: UserID) {
        (stream, continuation) = AsyncStream.makeStream(of: UserID.self)
        continuation.yield(userID)
    }

    func send(_ userID: UserID) {
        continuation.yield(userID)
    }
}
