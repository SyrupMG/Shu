//
//  Middleware.swift
//  Shu
//
//  Created by Лысенко Алексей Димитриевич on 30/10/2018.
//

import Foundation
import Alamofire

public protocol Middleware {
    /**
     Следует ожидать, что на вход в блок попадает **Operation<T>, T.Type**
     
     Это можно использовать для того чтобы использовать разные заголовке в зависимости от операции
     */
    typealias HeadersExtensionBlock = (AnyOperation, Any) -> [String: String]
    func headers(_ headersExtensionBlock: @escaping HeadersExtensionBlock)

    /**
     Следует ожидать, что на вход в блок попадет **Operation<T>, T.Type**
     
     Такое решение сделано для того, чтобы можно было писать один блокер для всех типов запросов
     Если бы был строгий <T>, пришлось бы писать для каждого типа запросов отдельный блокер, что не очень удобно
    */
    typealias RequestBarierBlock = (AnyOperation, Any) async throws -> Void
    func requestBarier(_ requestBarierBlock: @escaping RequestBarierBlock)

    typealias ResponseValidationBlock = (_: Int, _ headers: [AnyHashable: Any], _ data: Data?) throws -> Void
    func validateResponse(_ responseValidationBlock: @escaping ResponseValidationBlock)

    /**
     Следует ожидать, что на вход в блок попадает **Error, Operation<T>, T.Type**
     
     см. RequestBarierBlock
     */
    typealias RecoverBlock = (Error, AnyOperation, Any) async throws -> Void
    func recover(_ recoverBlock: @escaping RecoverBlock)

    /**
     Следует ожидать, что на вход попадет **T, Operation<T>, T.Type**
     
     см. RequestBarierBlock
     */
    typealias SuccessBlock = (Any, AnyOperation, Any) -> Void
    func success(_ successBlock: @escaping SuccessBlock)
}
