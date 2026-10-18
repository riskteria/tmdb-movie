import Foundation

nonisolated struct AsyncBroadcaster<Value: Sendable> {
    private var continuations: [UUID: AsyncStream<Value>.Continuation] = [:]

    var subscriberCount: Int {
        continuations.count
    }

    mutating func subscribe(startingWith initialValue: Value? = nil) -> AsyncStream<Value> {
        let (stream, continuation) = AsyncStream.makeStream(of: Value.self, bufferingPolicy: .bufferingNewest(1))
        continuations[UUID()] = continuation
        if let initialValue {
            continuation.yield(initialValue)
        }
        return stream
    }

    mutating func send(_ value: Value) {
        continuations = continuations.filter { _, continuation in
            if case .terminated = continuation.yield(value) {
                return false
            }
            return true
        }
    }
}
