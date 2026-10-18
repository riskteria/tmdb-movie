import Foundation
import SwiftData

@Model
nonisolated final class SpikeRecord {
    var name: String

    init(name: String) {
        self.name = name
    }
}

@ModelActor
actor SpikeStore {
    func insert(_ name: String) throws {
        modelContext.insert(SpikeRecord(name: name))
        try modelContext.save()
    }

    func count() throws -> Int {
        try modelContext.fetchCount(FetchDescriptor<SpikeRecord>())
    }

    func isOnMainThread() -> Bool {
        pthread_main_np() != 0
    }
}
