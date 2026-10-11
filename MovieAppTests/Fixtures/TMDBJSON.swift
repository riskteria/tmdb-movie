import Foundation

enum TMDBJSON {
    static func decode<Value: Decodable>(_ type: Value.Type, from json: String) throws -> Value {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(type, from: Data(json.utf8))
    }
}
