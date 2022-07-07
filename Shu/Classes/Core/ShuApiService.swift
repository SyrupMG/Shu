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

public class ShuApiService: ApiService {
    private class BasicMiddleware: Middleware {
        fileprivate var headersExtensionBlock: HeadersExtensionBlock?
        func headers(_ headersExtensionBlock: @escaping HeadersExtensionBlock) {
            self.headersExtensionBlock = headersExtensionBlock
        }

        fileprivate var requestBarierBlock: RequestBarierBlock?
        func requestBarier(_ requestBarierBlock: @escaping RequestBarierBlock) {
            self.requestBarierBlock = requestBarierBlock
        }

        fileprivate var responseValidationBlock: ResponseValidationBlock?
        func validateResponse(_ responseValidationBlock: @escaping ResponseValidationBlock) {
            self.responseValidationBlock = responseValidationBlock
        }

        fileprivate var recoverBlock: RecoverBlock?
        func recover(_ recoverBlock: @escaping RecoverBlock) {
            self.recoverBlock = recoverBlock
        }

        fileprivate var successBlock: SuccessBlock?
        func success(_ successBlock: @escaping SuccessBlock) {
            self.successBlock = successBlock
        }
    }

    private let session: Session
    private var middlewares = [BasicMiddleware]()
    private var queue: DispatchQueue {
        return session.session.delegateQueue.underlyingQueue ?? DispatchQueue.global(qos: .utility)
    }

    // MARK: -init
    required public init(eventMonitors: [EventMonitor] = []) {
        let configuration = URLSessionConfiguration.default
        session = Alamofire.Session(configuration: configuration, eventMonitors: eventMonitors)
    }

    // MARK: - methods
    public func addMiddleware(_ middlewareConfigBlock: MiddlewareConfigBlock) {
        let middleware = BasicMiddleware()
        middlewareConfigBlock(middleware)
        middlewares.append(middleware)
    }

    private func make<OP: Operation>(_ operation: OP) -> DataRequest {
        var urlComps = URLComponents(string: operation.baseURL)!
        urlComps.path = operation.path
        if operation.trailingSlash, !urlComps.path.hasSuffix("/") { urlComps.path += "/" }
        
        urlComps.queryItems = operation.queryParams?.map { URLQueryItem(name: $0.0, value: $0.1) }
        urlComps.percentEncodedQuery = urlComps.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
        
        var urlRequest = URLRequest(url: urlComps.url!)
        urlRequest.httpMethod = operation.httpMethod
        urlRequest.httpBody = operation.httpBody
        
        var headers = [String: String]()
        middlewares.forEach { middleware in
            headers.merge(middleware.headersExtensionBlock?(operation, OP.ResultType.self) ?? [:]) { _, new in new }
        }
        headers.forEach { urlRequest.setValue($0.value, forHTTPHeaderField: $0.key) }

        let dataRequest = self.session.request(urlRequest)
        // TODO: - это хук вокруг ляжки на случай, если в заголовках попадается Basic авторизация. Ее надо проксировать в авторизацию URLSession
        // т.к. иногда она работает более корректно. По хорошему, надо наружу вытащить возможность настраивать авторизацию
        if let authorization = headers["Authorization"],
            authorization.hasPrefix("Basic"),
            let authToken = authorization.components(separatedBy: " ").last,
            let decodedTokenData = Data(base64Encoded: authToken),
            let decodedToken = String(data: decodedTokenData, encoding: .utf8) {
            let decodedTokenParts = decodedToken.components(separatedBy: ":")
            if decodedTokenParts.count == 2,
                let username = decodedTokenParts.first,
                let password = decodedTokenParts.last {
                dataRequest.authenticate(username: username, password: password)
            }
        }

        dataRequest.validate({ (request, response, data) -> Request.ValidationResult in
            // look thru all the middlewares for first responseValidationBlock to throw error
            if let error = self.middlewares.firstResult(where: { (middleware) -> Error? in
                // if there is any validationblock
                guard let validate = middleware.responseValidationBlock else { return nil }
                do {
                    // try to validate
                    try validate(response.statusCode, response.allHeaderFields, data)
                    return nil
                } catch {
                    // if error throwed, return it, so we can fail the request
                    return error
                }
            }) {
              return .failure(error)
            }

            return .success(())
        })

        return dataRequest
    }

    public func makeRaw<OP: Operation>(_ operation: OP) -> Promise<Data?> {
        let dataRequest: DataRequest = make(operation)
        
        return Promise { (resolver) in
            dataRequest.response(queue: queue) {
                switch $0.result {
                case .success(let data):
                    resolver.fulfill(data)
                case .failure(let error):
                    resolver.reject(error)
                }
            }
        }
    }

    public func make<OP: Operation>(_ operation: OP) -> Promise<OP.ResultType> {
        let barierBlocks = middlewares.compactMap { $0.requestBarierBlock }
        return when(fulfilled: barierBlocks.map { $0(operation, OP.ResultType.self) })
            .then(on: queue) { _ -> Promise<OP.ResultType> in
                return self.makeRaw(operation)
                    .compactMap(on: self.queue) { $0 }
                    .map(on: self.queue) { data -> OP.ResultType in
                        let res = try operation.proceed(data: data)
                        self.middlewares.forEach { $0.successBlock?(res, operation, OP.ResultType.self) }
                        return res
                    }
                    .recover(on: self.queue) { error throws -> Promise<OP.ResultType> in
                        return self.handle(error: error, for: operation) as Promise<OP.ResultType>
                    }
            }
    }

    private func handle<OP: Operation>(error: Error, for operation: OP) -> Promise<OP.ResultType> {
        var errorPromisesIterator = middlewares
            .compactMap { $0.recoverBlock }
            .map { $0(error, operation, OP.ResultType.self) }.lazy.makeIterator()

        func next() -> Promise<Void> {
            // If there is any next recover block, try it
            guard let nextRecoverBlock = errorPromisesIterator.next() else { return Promise(error: error) }

            return nextRecoverBlock
                // if recover block resolves, resolve promise chain with Void
                .then(on: queue) { value -> Promise<Void> in
                    return Promise.value(())
                }
                // If recover block raises error, try next recover block
                .recover(on: queue) { error -> Promise<Void> in
                    return next()
                }
        }

        // Start recovering chain. If resolves, try make operation again
        return next().then { return self.make(operation) }
    }
}
