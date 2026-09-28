import Foundation

nonisolated struct Video: Identifiable, Hashable, Sendable {
    enum Kind: Sendable {
        case trailer
        case teaser
        case clip
        case featurette
        case behindTheScenes
        case other
    }

    let id: String
    let key: String
    let name: String
    let kind: Kind
    let publishedAt: Date?
}
