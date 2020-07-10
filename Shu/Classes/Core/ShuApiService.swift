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

    private let baseUrl: String
    private let sessionManager: SessionManager
    private var middlewares = [BasicMiddleware]()
    private var queue: DispatchQueue {
        return sessionManager.session.delegateQueue.underlyingQueue ?? DispatchQueue.global(qos: .utility)
    }

    // MARK: -init

    required public init(baseUrl: String) {
        let configuration = URLSessionConfiguration.default
        sessionManager = Alamofire.SessionManager(configuration: configuration)

        self.baseUrl = baseUrl
    }

    // MARK: - methods

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

        let needTrailingSlash = stringParts.last?.hasSuffix("/") ?? false
        return basePart + trailingParts + (needTrailingSlash ? "/" : "")
    }

    private func make<ResultType>(operation: Operation<ResultType>) -> DataRequest {
        let preparedUrl = prepareUrl(fromBase: baseUrl, andParts: operation.path)

        var headers = HTTPHeaders()
        middlewares.forEach { middleware in
            headers.merge(middleware.headersExtensionBlock?(Operation<ResultType>.self) ?? [:]) { _, new in new }
        }

        var dataRequest: DataRequest!

        var urlComps = URLComponents(string: preparedUrl)!
        urlComps.queryItems = operation.queryParams?.map { URLQueryItem(name: $0.key, value: String(describing:$0.value)) }
        urlComps.percentEncodedQuery = urlComps.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
        
        var urlRequest = URLRequest(url: urlComps.url!)
        urlRequest.httpMethod = operation.httpMethod.rawValue
        headers.forEach { urlRequest.setValue($0.value, forHTTPHeaderField: $0.key) }
        urlRequest.httpBody = operation.httpBody

        dataRequest = self.sessionManager.request(urlRequest)
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
                dataRequest = dataRequest.authenticate(user: username, password: password)
            }
        }

        dataRequest = dataRequest.log(options: [.jsonPrettyPrint], printer: AstarothPrinter())

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

            return .success
        })

        return dataRequest
    }

    public func makeRaw<ResultType>(operation: Operation<ResultType>) -> Promise<DefaultDataResponse> {
        let dataRequest: DataRequest = make(operation: operation)

        return Promise(resolver: { (resolver) in
            dataRequest
                .response(queue: queue, completionHandler: { (response) in
                    resolver.fulfill(response)
                })
        })
    }

    public func make<ResultType>(operation: Operation<ResultType>) -> Promise<ResultType> {
        let barierBlocks = middlewares.compactMap { $0.requestBarierBlock }
        return when(fulfilled: barierBlocks.map { $0(operation) }).then(on: queue) { _ -> Promise<ResultType> in
            let dataRequest: DataRequest = self.make(operation: operation)

            return dataRequest
                .response(.promise, queue: self.queue)
                .map(on: self.queue) { (request, response, data) -> ResultType in
                    let res: ResultType = try ResultType.apiMapper.decode(data)
                    self.middlewares.forEach { $0.successBlock?(res) }
                    return res
            }
            .recover(on: self.queue) { error throws -> Promise<ResultType> in
                return self.handle(error: error, for: operation) as Promise<ResultType>
            }
        }

    }

    private func handle<ResultType>(error: Error, for operation: Operation<ResultType>) -> Promise<ResultType> {
        var errorPromisesIterator = middlewares
            .compactMap { $0.recoverBlock }
            .map { $0(error, operation) }.lazy.makeIterator()

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
        return next().then { return self.make(operation: operation) }
    }
}

import Astaroth

private class AstarothPrinter: Printer {
    private var requestString: String = ""
    func print(_ string: String, phase: Phase) {
        switch phase {
        case .request:
            requestString = string
            Log.d(Network, string)
        case .response(let success):
            let string = "\(requestString)\n\(string)"
            if success { Log.i(Network, string) }
            else { Log.e(Network, string) }
        }
    }
}
