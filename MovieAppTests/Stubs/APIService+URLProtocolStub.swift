import Alamofire
import Foundation
@testable import MovieApp

extension APIService {
    static func makeStub() -> APIService {
        let configuration = URLSessionConfiguration.af.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        return APIService(configuration: configuration)
    }
}
