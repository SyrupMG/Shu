//
//  Operation.swift
//  Shu
//
//  Created by Алексей Лысенко on 09.05.2018.
//  Copyright © 2018 Syrup Media Group. All rights reserved.
//

import Foundation
import Alamofire
import PromiseKit

public typealias HTTPMethod = Alamofire.HTTPMethod

public class Operation<ResultType: ApiMappable>: Thenable {
    // MARK: - Thenable
    
    private lazy var cancelationPromise = Promise<ResultType>.pending()
    private lazy var promise = ApiServiceLocator.mainApiService!.make(operation: self)
    
    public func pipe(to: @escaping (PromiseKit.Result<ResultType>) -> Void) {
        race([cancelationPromise.promise, promise]).pipe(to: to)
    }
    public var result: PromiseKit.Result<ResultType>? { return promise.result }
    
    public enum Payload {
        case parameters(_: Parameters?)
        case httpBody(_: Data?)
    }

    public let path: String
    public let httpMethod: HTTPMethod
    
    public var requestPayload: Payload = .parameters(nil)
    public var encoding: ParameterEncoding?
    
    public init(path: String, httpMethod: HTTPMethod) {
        self.path = path
        self.httpMethod = httpMethod
    }
    
    public func cancel() {
        // TODO: - дополнительно надо отменять сетевую операцию, иначе как-то бессмысленно
        cancelationPromise.resolver.reject(PMKError.cancelled)
    }
}
