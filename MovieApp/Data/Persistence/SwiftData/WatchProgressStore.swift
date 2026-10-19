import Foundation
import SwiftData

@ModelActor
actor WatchProgressStore {
    private var revision = 0

    func records(for accountID: Account.ID) throws -> StoreResult<[WatchProgress]> {
        let records = try fetchRecords(for: accountID).compactMap { record in makeWatchProgress(from: record) }
        return StoreResult(revision: revision, value: records)
    }

    func upsert(_ progress: WatchProgress, for accountID: Account.ID) throws -> StoreResult<[WatchProgress]> {
        try write(for: accountID) {
            if let record = try fetchRecord(progress.contentID, mediaType: progress.mediaType, for: accountID) {
                record.update(from: progress)
            } else {
                modelContext.insert(WatchProgressRecord(progress: progress, accountID: accountID))
            }
        }
    }

    func progress(for contentID: Int, mediaType: MediaType, of accountID: Account.ID) throws -> WatchProgress? {
        let record = try fetchRecord(contentID, mediaType: mediaType, for: accountID)
        return record.flatMap { record in makeWatchProgress(from: record) }
    }

    func removeAll(for accountID: Account.ID) throws -> StoreResult<[WatchProgress]> {
        try write(for: accountID) {
            try fetchRecords(for: accountID).forEach { record in modelContext.delete(record) }
        }
    }
}

private extension WatchProgressStore {
    func write(for accountID: Account.ID, _ changes: () throws -> Void) throws -> StoreResult<[WatchProgress]> {
        do {
            try changes()
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }
        revision += 1
        return try records(for: accountID)
    }

    func fetchRecords(for accountID: Account.ID) throws -> [WatchProgressRecord] {
        let descriptor = FetchDescriptor<WatchProgressRecord>(
            predicate: #Predicate { $0.accountID == accountID },
            sortBy: [SortDescriptor(\.lastWatchedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchRecord(_ contentID: Int, mediaType: MediaType, for accountID: Account.ID) throws -> WatchProgressRecord? {
        let mediaTypeValue = mediaType.rawValue
        var descriptor = FetchDescriptor<WatchProgressRecord>(
            predicate: #Predicate { record in
                record.accountID == accountID && record.contentID == contentID && record.mediaType == mediaTypeValue
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
