import Foundation
import os
import SwiftData

nonisolated struct AppModelContainer: Sendable {
    let modelContainer: ModelContainer
    let isPersistent: Bool

    init() {
        self.init(storeURL: .applicationSupportDirectory.appending(path: "MovieApp.store"))
    }

    init(isStoredInMemoryOnly: Bool) {
        if isStoredInMemoryOnly {
            self.init(modelContainer: makeInMemoryModelContainer(), isPersistent: false)
        } else {
            self.init()
        }
    }

    init(storeURL: URL) {
        let schema = Schema(versionedSchema: MovieAppSchemaV1.self)
        try? FileManager.default.createDirectory(
            at: storeURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        do {
            modelContainer = try ModelContainer(
                for: schema,
                migrationPlan: MovieAppMigrationPlan.self,
                configurations: ModelConfiguration(schema: schema, url: storeURL)
            )
            isPersistent = true
        } catch {
            let code = (error as NSError).code
            Logger(subsystem: "com.enkidu.MovieApp", category: "persistence").error(
                "Store failed to open with code \(code, privacy: .public) at \(storeURL.path, privacy: .private)"
            )
            modelContainer = makeInMemoryModelContainer()
            isPersistent = false
        }
    }

    private init(modelContainer: ModelContainer, isPersistent: Bool) {
        self.modelContainer = modelContainer
        self.isPersistent = isPersistent
    }
}

private nonisolated func makeInMemoryModelContainer() -> ModelContainer {
    let schema = Schema(versionedSchema: MovieAppSchemaV1.self)
    let configuration = ModelConfiguration(UUID().uuidString, schema: schema, isStoredInMemoryOnly: true)
    do {
        return try ModelContainer(for: schema, migrationPlan: MovieAppMigrationPlan.self, configurations: configuration)
    } catch {
        fatalError("In-memory store failed to open: \(error)")
    }
}
