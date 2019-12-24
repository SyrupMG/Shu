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
    enum Error: Swift.Error {
        case apiServiceNotFound
    }
    
    // MARK: - Thenable
    
    private lazy var cancelationPromise = Promise<ResultType>.pending()
    private lazy var promise = ApiServiceLocator.makeService(withIdentifier: apiServiceId)?.make(operation: self) ?? Promise(error: Error.apiServiceNotFound)
    private let apiServiceId: ApiServiceLocator.ApiServiceProducerId
    
    public func pipe(to: @escaping (PromiseKit.Result<ResultType>) -> Void) {
        race([cancelationPromise.promise, promise]).pipe(to: to)
    }
    public var result: PromiseKit.Result<ResultType>? { return promise.result }

    public let path: String
    public let httpMethod: HTTPMethod
    
    public var queryParams: Parameters? = nil
    public var httpBody: Data?
    
    public var encoding: ParameterEncoding?
    
    public init(path: String, httpMethod: HTTPMethod, apiServiceId: ApiServiceLocator.ApiServiceProducerId) {
        self.path = path
        self.httpMethod = httpMethod
        self.apiServiceId = apiServiceId
    }
    
    deinit {
        if cancelationPromise.promise.isPending {
            cancelationPromise.resolver.reject(PMKError.cancelled)
        }
    }
    
    public func cancel() {
        // TODO: - дополнительно надо отменять сетевую операцию, иначе как-то бессмысленно
        cancelationPromise.resolver.reject(PMKError.cancelled)
    }
}
