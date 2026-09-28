import Alamofire

nonisolated enum NetworkError: Error, Equatable {
    case invalidResponse(statusCode: Int)
    case decodingFailed
    case requestFailed

    init(_ error: AFError) {
        if let statusCode = error.responseCode {
            self = .invalidResponse(statusCode: statusCode)
        } else if error.isResponseSerializationError {
            self = .decodingFailed
        } else {
            self = .requestFailed
        }
    }
}
