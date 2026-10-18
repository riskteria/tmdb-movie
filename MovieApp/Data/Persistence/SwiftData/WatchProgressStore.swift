import Foundation
import SwiftData

@ModelActor
actor WatchProgressStore {
    private var revision = 0

    func records(for userID: UserID) throws -> StoreResult<[WatchProgress]> {
        let records = try fetchRecords(for: userID).compactMap { record in makeWatchProgress(from: record) }
        return StoreResult(revision: revision, value: records)
    }

    func upsert(_ progress: WatchProgress, for userID: UserID) throws -> StoreResult<[WatchProgress]> {
        try write(for: userID) {
            if let record = try fetchRecord(progress.contentID, mediaType: progress.mediaType, for: userID) {
                record.update(from: progress)
            } else {
                modelContext.insert(WatchProgressRecord(progress: progress, userID: userID.rawValue))
            }
        }
    }

    func progress(for contentID: Int, mediaType: MediaType, of userID: UserID) throws -> WatchProgress? {
        let record = try fetchRecord(contentID, mediaType: mediaType, for: userID)
        return record.flatMap { record in makeWatchProgress(from: record) }
    }

    func removeAll(for userID: UserID) throws -> StoreResult<[WatchProgress]> {
        try write(for: userID) {
            try fetchRecords(for: userID).forEach { record in modelContext.delete(record) }
        }
    }
}

private extension WatchProgressStore {
    func write(for userID: UserID, _ changes: () throws -> Void) throws -> StoreResult<[WatchProgress]> {
        do {
            try changes()
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }
        revision += 1
        return try records(for: userID)
    }

    func fetchRecords(for userID: UserID) throws -> [WatchProgressRecord] {
        let owner = userID.rawValue
        let descriptor = FetchDescriptor<WatchProgressRecord>(
            predicate: #Predicate { $0.userID == owner },
            sortBy: [SortDescriptor(\.lastWatchedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchRecord(_ contentID: Int, mediaType: MediaType, for userID: UserID) throws -> WatchProgressRecord? {
        let owner = userID.rawValue
        let mediaTypeValue = mediaType.rawValue
        var descriptor = FetchDescriptor<WatchProgressRecord>(
            predicate: #Predicate { record in
                record.userID == owner && record.contentID == contentID && record.mediaType == mediaTypeValue
            }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    func makeWatchProgress(from record: WatchProgressRecord) -> WatchProgress? {
        guard let mediaType = MediaType(rawValue: record.mediaType) else { return nil }
        return WatchProgress(
            contentID: record.contentID,
            mediaType: mediaType,
            position: .seconds(record.positionSeconds),
            duration: .seconds(record.durationSeconds),
            videoKey: record.videoKey,
            lastWatchedAt: record.lastWatchedAt
        )
    }
}
