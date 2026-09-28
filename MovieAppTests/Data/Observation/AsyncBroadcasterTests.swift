@testable import MovieApp
import Testing

struct AsyncBroadcasterTests {
    @Test
    func everySubscriberReceivesSentValue() async {
        // Given
        let sut = AsyncBroadcaster<Int>()
        let first = await sut.subscribe()
        let second = await sut.subscribe()

        // When
        await sut.send(7)

        // Assert
        #expect(await first.first { _ in true } == 7)
        #expect(await second.first { _ in true } == 7)
    }

    @Test
    func subscriberStartsWithInitialValue() async {
        // Given
        let sut = AsyncBroadcaster<Int>()

        // When
        let stream = await sut.subscribe(startingWith: 3)

        // Assert
        #expect(await stream.first { _ in true } == 3)
    }

    @Test
    func slowSubscriberGetsNewestValue() async {
        // Given
        let sut = AsyncBroadcaster<Int>()
        let stream = await sut.subscribe()

        // When
        await sut.send(1)
        await sut.send(2)

        // Assert
        #expect(await stream.first { _ in true } == 2)
    }

    @Test(.timeLimit(.minutes(1)))
    func cancelledSubscriberIsRemoved() async {
        // Given
        let sut = AsyncBroadcaster<Int>()
        let subscriber = Task {
            for await _ in await sut.subscribe() {}
        }
        while await sut.subscriberCount == 0 {
            await Task.yield()
        }

        // When
        subscriber.cancel()
        await subscriber.value
        while await sut.subscriberCount > 0 {
            await Task.yield()
        }

        // Assert
        #expect(await sut.subscriberCount == 0)
    }
}
