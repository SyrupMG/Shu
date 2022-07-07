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

    func make<OP: Operation>(_ operation: OP) -> Promise<OP.ResultType>
    func makeRaw<OP: Operation>(_ operation: OP) -> Promise<Data?>
    
    func addMiddleware(_ middlewareConfigBlock: MiddlewareConfigBlock)
}
