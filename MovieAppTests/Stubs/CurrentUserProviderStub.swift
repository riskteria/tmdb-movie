@testable import MovieApp

final class CurrentUserProviderStub: CurrentUserProvider {
    private let stream: AsyncStream<Account.ID?>
    private let continuation: AsyncStream<Account.ID?>.Continuation

    var accountIDs: AsyncStream<Account.ID?> {
        get async {
            stream
        }
    }

    init(accountID: Account.ID?) {
        (stream, continuation) = AsyncStream.makeStream(of: Account.ID?.self)
        continuation.yield(accountID)
    }

    func send(_ accountID: Account.ID?) {
        continuation.yield(accountID)
    }
}
