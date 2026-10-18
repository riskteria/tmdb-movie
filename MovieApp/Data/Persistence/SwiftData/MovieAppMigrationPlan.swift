import SwiftData

nonisolated enum MovieAppMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [MovieAppSchemaV1.self]
    }

    static var stages: [MigrationStage] {
        []
    }
}
