import Foundation
import SwiftData

typealias SavedMovieRecord = MovieAppSchemaV1.SavedMovieRecord
typealias WatchProgressRecord = MovieAppSchemaV1.WatchProgressRecord

nonisolated enum MovieAppSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version {
        Schema.Version(1, 0, 0)
    }

    static var models: [any PersistentModel.Type] {
        [SavedMovieRecord.self, WatchProgressRecord.self]
    }

    @Model
    final class SavedMovieRecord {
        #Unique<SavedMovieRecord>([\.userID, \.movieID])
        #Index<SavedMovieRecord>([\.userID, \.savedAt])

        var userID: String
        var movieID: Int
        var title: String
        var overview: String
        var releaseDate: Date?
        var posterPath: String?
        var backdropPath: String?
        var genreIDs: [Int]
        var voteAverage: Double
        var savedAt: Date

        init(movie: Movie, userID: String, savedAt: Date) {
            self.userID = userID
            movieID = movie.id
            title = movie.title
            overview = movie.overview
            releaseDate = movie.releaseDate
            posterPath = movie.posterPath?.rawValue
            backdropPath = movie.backdropPath?.rawValue
            genreIDs = movie.genreIDs
            voteAverage = movie.voteAverage
            self.savedAt = savedAt
        }
    }

    @Model
    final class WatchProgressRecord {
        #Unique<WatchProgressRecord>([\.userID, \.contentID, \.mediaType])
        #Index<WatchProgressRecord>([\.userID, \.lastWatchedAt])

        var userID: String
        var contentID: Int
        var mediaType: String
        var positionSeconds: Double
        var durationSeconds: Double
        var videoKey: String
        var lastWatchedAt: Date

        init(progress: WatchProgress, userID: String) {
            self.userID = userID
            contentID = progress.contentID
            mediaType = progress.mediaType.rawValue
            positionSeconds = progress.position.totalSeconds
            durationSeconds = progress.duration.totalSeconds
            videoKey = progress.videoKey
            lastWatchedAt = progress.lastWatchedAt
        }

        func update(from progress: WatchProgress) {
            positionSeconds = progress.position.totalSeconds
            durationSeconds = progress.duration.totalSeconds
            videoKey = progress.videoKey
            lastWatchedAt = progress.lastWatchedAt
        }
    }
}

nonisolated extension Duration {
    var totalSeconds: Double {
        Double(components.seconds) + Double(components.attoseconds) / 1e18
    }
}
