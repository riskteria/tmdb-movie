import Foundation
@testable import MovieApp
import Synchronization

final class URLProtocolStub: URLProtocol {
    enum Response: Sendable {
        case json(statusCode: Int, body: String)
        case noResponse
    }

    private static let responses = Mutex<[String: Response]>([:])

    static func stub(_ endpoint: TMDBEndpoint, with response: Response) throws {
        let key = try endpoint.asURLRequest().url?.absoluteString ?? ""
        responses.withLock { $0[key] = response }
    }

    override static func canInit(with request: URLRequest) -> Bool {
        true
    }

    override static func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        let key = request.url?.absoluteString ?? ""
        let stubbed = Self.responses.withLock { $0[key] }
        switch stubbed {
        case let .json(statusCode, body):
            guard
                let url = request.url,
                let response = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)
            else {
                return
            }
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: Data(body.utf8))
            client?.urlProtocolDidFinishLoading(self)
        case .noResponse:
            break
        case nil:
            client?.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet))
        }
    }

    override func stopLoading() {}
}
