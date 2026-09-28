import Foundation
@testable import MovieApp
import Synchronization

// Serves canned responses keyed by URL, so APIClient and repository tests never touch the network.
// Swift Testing runs tests in parallel, so each test must stub a URL no other test uses, for
// example by giving each test its own page number.
final class URLProtocolStub: URLProtocol {
    enum Response: Sendable {
        case json(statusCode: Int, body: String)
        case failure(URLError)
        // Never answers, so the request stays in flight until it's cancelled.
        case noResponse
    }

    private static let responses = Mutex<[String: Response]>([:])
    private static let requests = Mutex<[String: URLRequest]>([:])

    static func stub(_ endpoint: TMDBEndpoint, with response: Response) throws {
        let key = try key(for: endpoint)
        responses.withLock { $0[key] = response }
    }

    static func lastRequest(for endpoint: TMDBEndpoint) throws -> URLRequest? {
        let key = try key(for: endpoint)
        return requests.withLock { $0[key] }
    }

    override static func canInit(with request: URLRequest) -> Bool {
        true
    }

    override static func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        let loadingRequest = request
        let key = loadingRequest.url?.absoluteString ?? ""
        Self.requests.withLock { $0[key] = loadingRequest }
        let response = Self.responses.withLock { $0[key] }
        switch response {
        case let .json(statusCode, body):
            respond(statusCode: statusCode, body: Data(body.utf8))
        case .failure(let error):
            client?.urlProtocol(self, didFailWithError: error)
        case .noResponse:
            break
        case nil:
            client?.urlProtocol(self, didFailWithError: URLError(.resourceUnavailable))
        }
    }

    override func stopLoading() {}
}

private extension URLProtocolStub {
    static func key(for endpoint: TMDBEndpoint) throws -> String {
        try endpoint.asURLRequest().url?.absoluteString ?? ""
    }

    func respond(statusCode: Int, body: Data) {
        guard let url = request.url else { return }
        let response = HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )
        guard let response else { return }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: body)
        client?.urlProtocolDidFinishLoading(self)
    }
}
