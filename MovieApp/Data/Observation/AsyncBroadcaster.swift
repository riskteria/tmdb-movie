import Foundation

// Fans one stream of values out to every subscriber. A plain AsyncStream allows only one consumer,
// but the Save button, the Saved tab and Home's Continue Watching row all observe the same changes.
actor AsyncBroadcaster<Value: Sendable> {
    private var continuations: [UUID: AsyncStream<Value>.Continuation] = [:]

    var subscriberCount: Int {
        continuations.count
    }

    func subscribe(startingWith initialValue: Value? = nil) -> AsyncStream<Value> {
        let (stream, continuation) = AsyncStream.makeStream(of: Value.self, bufferingPolicy: .bufferingNewest(1))
        let id = UUID()
        continuations[id] = continuation
        continuation.onTermination = { [weak self] _ in
            Task { await self?.unsubscribe(id) }
        }
        if let initialValue {
            continuation.yield(initialValue)
        }
        return stream
    }

    func send(_ value: Value) {
        continuations.values.forEach { continuation in continuation.yield(value) }
    }

    private func unsubscribe(_ id: UUID) {
        continuations[id] = nil
    }
}
