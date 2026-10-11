import Alamofire
import Foundation
@testable import Networking

extension APIService {
    static func makeStub() -> APIService {
        let configuration = URLSessionConfiguration.af.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        return APIService(configuration: configuration)
    }
}
