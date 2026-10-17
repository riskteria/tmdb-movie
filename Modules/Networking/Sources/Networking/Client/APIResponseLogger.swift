import Alamofire
import Foundation
import os

nonisolated struct APIResponseLogger: Sendable {
    private let logger = Logger(subsystem: "com.enkidu.MovieApp", category: "network")

    func log<Value>(_ response: DataResponse<Value, AFError>, for endpoint: TMDBEndpoint) {
        #if DEBUG
        let request = response.request
        let method = request?.httpMethod ?? endpoint.method.rawValue
        let status = response.response.map { String($0.statusCode) } ?? "-"
        if endpoint.carriesCredentials {
            let summary = "[Response] \(status) \(method) \(endpoint.path)"
            logger.debug("\(summary, privacy: .public)")
            return
        }
        let url = request?.url?.absoluteString ?? endpoint.path
        let requestLog = """
            [Request] \(method) \(url)
            Headers: \(Self.describe(request?.headers))
            Body: \(Self.describe(request?.httpBody))
            """
        let responseLog = """
            [Response] \(status) \(method) \(url)
            Headers: \(Self.describe(response.response?.headers))
            Body: \(Self.describe(response.data))
            """
        logger.debug("\(requestLog, privacy: .public)")
        logger.debug("\(responseLog, privacy: .public)")
        #endif
    }
}

private nonisolated extension APIResponseLogger {
    static func describe(_ headers: HTTPHeaders?) -> String {
        guard let headers, !headers.isEmpty else { return "-" }
        return headers
            .map { header in
                let isSecret = header.name.caseInsensitiveCompare("Authorization") == .orderedSame
                return "\(header.name): \(isSecret ? "<redacted>" : header.value)"
            }
            .joined(separator: ", ")
    }

    static func describe(_ body: Data?) -> String {
        guard let body, !body.isEmpty else { return "-" }
        return String(bytes: body, encoding: .utf8) ?? "<\(body.count) bytes, not UTF-8>"
    }
}
