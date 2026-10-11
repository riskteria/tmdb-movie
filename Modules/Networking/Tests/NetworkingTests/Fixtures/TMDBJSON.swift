import Foundation

enum TMDBJSON {
    static func decode<Value: Decodable>(_ type: Value.Type, from json: String) throws -> Value {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(type, from: Data(json.utf8))
    }

    static let movieSummaryFields = """
        "id": 693134,
        "title": "Dune: Part Two",
        "original_title": "Dune: Part Two",
        "original_language": "en",
        "overview": "Follow the mythic journey of Paul Atreides.",
        "poster_path": "/poster.jpg",
        "backdrop_path": null,
        "genre_ids": [878, 12],
        "release_date": "2024-02-27",
        "popularity": 512.4,
        "vote_average": 8.2,
        "vote_count": 6123,
        "adult": false,
        "video": false
        """
}
