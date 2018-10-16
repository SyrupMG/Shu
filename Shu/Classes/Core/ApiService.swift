//
//  ApiService.swift
//  guligram
//
//  Created by Alexey Lysenko on 04.05.2018.
//  Copyright © 2018 Syrup Media Group. All rights reserved.
//

import Foundation
import PromiseKit
import Alamofire
import AlamofireActivityLogger

public class ApiService {
    private let baseUrl: String
    private let sessionManager: SessionManager

    private var headersMutators = [HTTPHeadersMutator]()
    private var errorHandlers = [String: ErrorHandler]()
    private let errorMaker: ApiServiceErrorMaker

    public init(baseUrl: String, errorMaker: ApiServiceErrorMaker) {
        let configuration = URLSessionConfiguration.default
        sessionManager = Alamofire.SessionManager(configuration: configuration)

        self.errorMaker = errorMaker
        self.baseUrl = baseUrl
    }

    public func register(headersMutator: HTTPHeadersMutator) {
        headersMutators.append(headersMutator)
    }

    public typealias ErrorHandler = () -> Promise<Void>
    public func register<T: ApiServiceError>(forErrorType errorType: T.Type, handler: @escaping ErrorHandler) {
        let errorTypeId = String(describing: errorType)
        errorHandlers[errorTypeId] = handler
    }

    private func defaultHeaders() -> HTTPHeaders {
        return [:]
    }

    private func prepareUrl(fromBase base: String, andParts stringParts: String...) -> String {
        var basePart = base
        if basePart.last == "/" { basePart.removeLast() }
        let trailingParts = "/" + stringParts.flatMap {
            $0.split(separator: "/").map { String($0) }
        }.joined(separator: "/")
        return basePart + trailingParts
    }
    
    private func makeAllBeforeValidate<ResultType>(request: ApiRequest<ResultType>) -> DataRequest {
        let preparedUrl = prepareUrl(fromBase: baseUrl, andParts: request.pathPart)
        var headers = defaultHeaders()
        
        if let headersMutator = request as? HTTPHeadersMutator {
            headers = headersMutator.mutate(headers: headers)
        }
        headersMutators.forEach { headers = $0.mutate(headers: headers) }
        
        let encoding = request.encoding ?? URLEncoding.default
        
        var dataRequest: DataRequest!
        
        switch request.requestPayload {
        case .parameters(let parameters):
            dataRequest = self.sessionManager
                .request(preparedUrl,
                         method: request.httpMethod,
                         parameters: parameters,
                         encoding: encoding,
                         headers: headers)
        case .httpBody(let httpBody):
            var urlRequest = URLRequest(url: URL(string: preparedUrl)!)
            urlRequest.httpMethod = request.httpMethod.rawValue
            headers.forEach { urlRequest.setValue($0.value, forHTTPHeaderField: $0.key) }
            urlRequest.httpBody = httpBody
            
            dataRequest = self.sessionManager.request(urlRequest)
        }
        
        #if DEBUG
        dataRequest = dataRequest.log()
        #endif
        
        dataRequest.validate({ (request, response, data) -> Request.ValidationResult in
            if let error = self.errorMaker.error(fromStatusCode: response.statusCode, data: data) {
                return .failure(error)
            }
            return .success
        })
        
        return dataRequest
    }
    
    public func makeRaw<ResultType>(request: ApiRequest<ResultType>) -> Promise<DefaultDataResponse> {
        let dataRequest = makeAllBeforeValidate(request: request)
        
        return Promise(resolver: { (resolver) in
            dataRequest
                .response(completionHandler: { (response) in
                    resolver.fulfill(response)
                })
        })
    }

    public func make<ResultType>(request: ApiRequest<ResultType>) -> Promise<ResultType> {
        let dataRequest = makeAllBeforeValidate(request: request)

        return dataRequest
            .responseData()
            .then { data in
                return request.handle(finalResponse: dataRequest)
            }
            .recover { error throws -> Promise<ResultType> in
                if let apiServiceError = error as? ApiServiceError {
                    return self.handleError(error: apiServiceError, forRequest: request)
                }
                throw error
        }
    }

    private func handleError<ResultType>(error: ApiServiceError, forRequest: ApiRequest<ResultType>) -> Promise<ResultType> {
        // If error is complex, take first that can be handled, try to solve it and then make retry request
        if let complexError = error as? ApiServiceComplexError,
            let handleableError = (complexError.errors.first { errorHandlers[String(describing: type(of:$0))] != nil }),
            let errorHandler = errorHandlers[String(describing: type(of:handleableError))] {
            return errorHandler()
                .then { return self.make(request: forRequest) }
        } else if let errorHandler = errorHandlers[String(describing: type(of:error))] {
            return errorHandler()
                .then { return self.make(request: forRequest) }
        }
        return Promise(error: error)
    }
}
