//
//  ShuApiService.swift
//  Shu
//
//  Created by Alexey Lysenko on 04.05.2018.
//  Copyright © 2018 Syrup Media Group. All rights reserved.
//

import Foundation
import PromiseKit
import Alamofire
import AlamofireActivityLogger

public class ShuApiService: ApiService {
    private class BasicMiddleware: Middleware {
        fileprivate var headersMutationBlock: HeadersMutationBlock?
        func headers(_ headersMutationBlock: @escaping HeadersMutationBlock) {
            self.headersMutationBlock = headersMutationBlock
        }
        
        fileprivate var responseValidationBlock: ResponseValidationBlock?
        func validateResponse(_ responseValidationBlock: @escaping ResponseValidationBlock) {
            self.responseValidationBlock = responseValidationBlock
        }
        
        fileprivate var recoverBlock: RecoverBlock?
        func recover(_ recoverBlock: @escaping RecoverBlock) {
            self.recoverBlock = recoverBlock
        }
    }

    private let baseUrl: String
    private let sessionManager: SessionManager
    private var middlewares = [BasicMiddleware]()
    
    // MARK: -init

    required public init(baseUrl: String) {
        let configuration = URLSessionConfiguration.default
        sessionManager = Alamofire.SessionManager(configuration: configuration)

        self.baseUrl = baseUrl
    }
    
    // MARK: - methods

    private func defaultHeaders() -> HTTPHeaders { return [:] }

    public func addMiddleware(_ middlewareConfigBlock: MiddlewareConfigBlock) {
        let middleware = BasicMiddleware()
        middlewareConfigBlock(middleware)
        middlewares.append(middleware)
    }

    private func prepareUrl(fromBase base: String, andParts stringParts: String...) -> String {
        var basePart = base
        if basePart.last == "/" { basePart.removeLast() }
        let trailingParts = "/" + stringParts.flatMap {
            $0.split(separator: "/").map { String($0) }
        }.joined(separator: "/")
    
        return basePart + trailingParts
    }
    
    private func make<ResultType>(operation: Operation<ResultType>) -> DataRequest {
        let preparedUrl = prepareUrl(fromBase: baseUrl, andParts: operation.path)
        var headers = defaultHeaders()
        
        middlewares.forEach {
            guard let mutateHeaders = $0.headersMutationBlock else { return }
            headers = mutateHeaders(headers)
        }
        
        let encoding = operation.encoding ?? URLEncoding.default
        
        var dataRequest: DataRequest!
        
        switch operation.requestPayload {
        case .parameters(let parameters):
            dataRequest = self.sessionManager
                .request(preparedUrl,
                         method: operation.httpMethod,
                         parameters: parameters,
                         encoding: encoding,
                         headers: headers)
        case .httpBody(let httpBody):
            var urlRequest = URLRequest(url: URL(string: preparedUrl)!)
            urlRequest.httpMethod = operation.httpMethod.rawValue
            headers.forEach { urlRequest.setValue($0.value, forHTTPHeaderField: $0.key) }
            urlRequest.httpBody = httpBody
            
            dataRequest = self.sessionManager.request(urlRequest)
        }
        
        #if DEBUG
        dataRequest = dataRequest.log()
        #endif
        
        dataRequest.validate({ (request, response, data) -> Request.ValidationResult in
            // look thru all the middlewares for first responsevalidationblock to thrwo error
            if let error = self.middlewares.firstResult(where: { (middleware) -> Error? in
                // if there is any validationblock
                guard let validate = middleware.responseValidationBlock else { return nil }
                do {
                    // try to validate
                    try validate(response.statusCode, data)
                    return nil
                } catch {
                    // if error throwed, return it, so we can fail the request
                    return error
                }
            }) {
              return .failure(error)
            }
            
            return .success
        })
        
        return dataRequest
    }
    
    public func makeRaw<ResultType>(operation: Operation<ResultType>) -> Promise<DefaultDataResponse> {
        let dataRequest: DataRequest = make(operation: operation)
        
        return Promise(resolver: { (resolver) in
            dataRequest
                .response(completionHandler: { (response) in
                    resolver.fulfill(response)
                })
        })
    }

    public func make<ResultType>(operation: Operation<ResultType>) -> Promise<ResultType> {
        let dataRequest: DataRequest = make(operation: operation)

        return dataRequest
            .response(.promise)
            .map { (request, response, data) in
                return try ResultType.apiMapper.decode(data)
            }
            .recover { error throws -> Promise<ResultType> in
                return self.handle(error: error, for: operation) as Promise<ResultType>
            }
    }

    private func handle<ResultType>(error: Error, for operation: Operation<ResultType>) -> Promise<ResultType> {
        var errorPromisesIterator = middlewares
            .compactMap { $0.recoverBlock }
            .map { $0(error) }.lazy.makeIterator()
        
        func next() -> Promise<Void> {
            // If there is any next recover block, try it
            guard let nextRecoverBlock = errorPromisesIterator.next() else { return Promise(error: error) }
            
            return nextRecoverBlock
                // if recover block resolves, resolve promise chain with Void
                .then { value -> Promise<Void> in
                    return Promise.value(())
                }
                // If recover block raises error, try next recover block
                .recover { error -> Promise<Void> in
                    return next()
                }
        }
        
        // Start recovering chain. If resolves, try make operation again
        return next().then { return self.make(operation: operation) }
    }
}
