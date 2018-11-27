//
//  Middleware.swift
//  Shu
//
//  Created by Лысенко Алексей Димитриевич on 30/10/2018.
//

import Foundation
import Alamofire
import PromiseKit

public protocol Middleware {
    typealias HeadersMutationBlock = (HTTPHeaders) -> HTTPHeaders
    func headers(_ headersMutationBlock: @escaping HeadersMutationBlock)
    
    typealias ResponseValidationBlock = (_: Int, _ data: Data?) throws -> Void
    func validateResponse(_ responseValidationBlock: @escaping ResponseValidationBlock)
    
    typealias RecoverBlock = (Error) -> Promise<Void>
    func recover(_ recoverBlock: @escaping RecoverBlock)
}
