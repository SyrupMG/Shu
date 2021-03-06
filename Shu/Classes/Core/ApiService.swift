//
//  ApiService.swift
//  Shu
//
//  Created by Лысенко Алексей Димитриевич on 18/10/2018.
//

import Foundation
import Alamofire
import PromiseKit

public protocol ApiService: AnyObject {
    typealias MiddlewareConfigBlock = (Middleware) -> Void

    init(baseUrl: String)
    func make<ResultType>(operation: Operation<ResultType>) -> Promise<ResultType>
    func makeRaw<ResultType>(operation: Operation<ResultType>) -> Promise<DefaultDataResponse>
    
    func addMiddleware(_ middlewareConfigBlock: MiddlewareConfigBlock)
}

extension ApiService {
    public func setAsMain() { ApiServiceLocator.setMainProducer { [weak self] in return self } }
}
