//
//  ApiRequest.swift
//  guligram
//
//  Created by Алексей Лысенко on 09.05.2018.
//  Copyright © 2018 Syrup Media Group. All rights reserved.
//

import Foundation
import Alamofire
import PromiseKit

public typealias HTTPMethod = Alamofire.HTTPMethod

open class ApiRequest<ResultType> {
    public enum Payload {
        case parameters(_: Parameters?)
        case httpBody(_: Data?)
    }

    public let pathPart: String
    public let httpMethod: HTTPMethod
    
    public var requestPayload: Payload { return .parameters(nil) }
    
    public var encoding: ParameterEncoding? { return nil }
    
    public init(pathPart: String, httpMethod: HTTPMethod) {
        self.pathPart = pathPart
        self.httpMethod = httpMethod
    }
    
    public func handle(finalResponse: DataRequest) -> Promise<ResultType> {
        fatalError("NEVER USE BASE CLASS")
    }
}
