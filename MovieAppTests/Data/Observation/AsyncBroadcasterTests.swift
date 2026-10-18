@testable import MovieApp
import Testing

struct AsyncBroadcasterTests {
    @Test
    func subscriberReceivesStartingValue() async {
        // Given
        var sut = AsyncBroadcaster<Int>()

        // When
        let stream = sut.subscribe(startingWith: 3)

        // Assert
        #expect(await stream.first { _ in true } == 3)
    }

    @Test
    func sendReachesEverySubscriber() async {
        // Given
        var sut = AsyncBroadcaster<Int>()
        let first = sut.subscribe()
        let second = sut.subscribe()

        // When
        sut.send(7)

        // Assert
        #expect(await first.first { _ in true } == 7)
        #expect(await second.first { _ in true } == 7)
    }

    @Test(.timeLimit(.minutes(1)))
    func terminatedSubscriberIsDroppedOnNextSend() async {
        // Given
        var sut = AsyncBroadcaster<Int>()
        let stream = sut.subscribe()
        let subscriber = Task {
            for await _ in stream {}
        }
        subscriber.cancel()
        await subscriber.value

        // When
        sut.send(1)

        // Assert
        #expect(sut.subscriberCount == 0)
    }
}
