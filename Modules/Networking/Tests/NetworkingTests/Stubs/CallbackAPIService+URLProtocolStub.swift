import Alamofire
import Foundation
@testable import Networking

extension CallbackAPIService {
    static func makeStub() -> CallbackAPIService {
        let configuration = URLSessionConfiguration.af.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        return CallbackAPIService(configuration: configuration)
    }
}
