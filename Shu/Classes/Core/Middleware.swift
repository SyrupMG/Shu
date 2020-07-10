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
    /**
     Следует ожидать, что на вход в блок попадает **Operation<T: ApiMappable>.Type**
     
     Это можно использовать для того чтобы использовать разные заголовке в зависимости от операции
     */
    typealias HeadersExtensionBlock = (Any) -> HTTPHeaders
    func headers(_ headersExtensionBlock: @escaping HeadersExtensionBlock)

    /**
     Следует ожидать, что на вход в блок попадет **Operation<T: ApiMappable>**
     
     Такое решение сделано для того, чтобы можно было писать один блокер для всех типов запросов
     Если бы был строгий <T>, пришлось бы писать для каждого типа запросов отдельный блокер, что не очень удобно
    */
    typealias RequestBarierBlock = (Any) -> Promise<Void>
    func requestBarier(_ requestBarierBlock: @escaping RequestBarierBlock)

    typealias ResponseValidationBlock = (_: Int, _ headers: [AnyHashable: Any], _ data: Data?) throws -> Void
    func validateResponse(_ responseValidationBlock: @escaping ResponseValidationBlock)

    /**
     Следует ожидать, что на вход в блок в месте Any попадет **Operation<T: ApiMappable>**
     
     см. RequestBarierBlock
     */
    typealias RecoverBlock = (Error, Any) -> Promise<Void>
    func recover(_ recoverBlock: @escaping RecoverBlock)

    /**
     Следует ожидать, что на вход попадет **(T: ApiMappable)**
     
     см. RequestBarierBlock
     */
    typealias SuccessBlock = (Any) -> Void
    func success(_ successBlock: @escaping SuccessBlock)
}
